require 'heathrow'
require 'heathrow/queue'

require 'statemachine'

class Heathrow::Task
  def self.find(id)
    Marshal.load(Heathrow.store.get("task:#{id}"))
  end

  def initialize(git_repo, git_id)
    @git_repo = git_repo
    @git_id   = git_id

    task = self
    @state = Statemachine.build do
      trans :pending, :start, :incoming

      state :incoming do
        event :source_remote, :remote_fetching
        event :source_local,  :local_fetching
        on_entry :check_source
      end

      state :remote_fetching do
        event :fetched, :bundle_checking
        on_entry :queue_remote_fetch
      end

      state :local_fetching do
        event :fetched, :bundle_checking
        on_entry :queue_local_fetch
      end

      state :bundle_checking do
        event :bundle_incomplete, :bundle_installing
        event :bundle_complete,   :testing
        on_entry :queue_bundle_check
      end

      state :bundle_installing do
        event :bundle_installed, :testing
        on_entry :queue_bundle_install
      end

      state :testing do
        event :test_complete, :done
        on_entry :queue_test
      end

      state :done
      context task
    end
  end

  def id
    @id ||= generate_id
  end

  def check_source
    repo_local? ? @state.source_local : @state.source_remote
  end

  def repo_local?
    Heathrow::Git.repo_local?(@git_repo)
  end

  def save
    Heathrow.store.set("task:#{id}", Marshal.dump(self))
  end

  def queue_local_fetch
    Heathrow::Queue.local_fetch_queue << self
  end
  def queue_remote_fetch
    Heathrow::Queue.remote_fetch_queue << self
  end
  def queue_bundle_check
    Heathrow::Queue.bundle_check_queue << self
  end
  def queue_test
    Heathrow::Queue.test_queue << self
  end

  def start
    @state.start
  end

  def git_fetch
    repo = Heathrow.repository
    repo.fetch_branches(@git_repo)
    repo.tag_remote_branch(tag_name, @git_repo, @git_id)

    @state.fetched
  end

  def bundle_check
    tree = Heathrow.bundle_check_tree
    tree.git.fetch_tags(Heathrow.repository.path)
    tree.git.checkout(tag_name)

    begin
      tree.run('bundle', 'check')
      @state.bundle_complete
    rescue Heathrow::Tree::CommandFailed
      @state.bundle_incomplete
    end
  end

  private

  # Not a UUID because emphasis is on local uniqueness.
  def generate_id
    now = Time.now
    parts = [now.to_i, now.usec, $$, rand(16**8)]
    parts.map {|i| i.to_s(16)}.join('-')
  end

  def tag_name
    "task-#{id}"
  end
end
