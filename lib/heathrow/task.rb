require 'heathrow'

require 'statemachine'

class Heathrow::Task
  def self.new(git_repo, git_id)
    machine = Statemachine.build do
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
    end
    machine.context = Context.new(machine, git_repo, git_id)
    machine
  end

  class Context
    def initialize(state, git_repo, git_id)
      @state    = state
      @git_repo = git_repo
      @git_id   = git_id
    end

    def id
      @id ||= generate_id
    end

    def check_source
      repo_local? ? @state.source_local : @state.source_remote
    end

    def repo_local?
      @git_repo.end_with?('_local')
    end

    private

    def generate_id
      now = Time.now
      parts = [now.to_i, now.usec, $$, rand(16**8)]
      parts.map {|i| i.to_s(16)}.join('-')
    end
  end
end
