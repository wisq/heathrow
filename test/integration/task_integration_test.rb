require 'minitest/autorun'

require 'test_helper'
require 'heathrow/task'

class TaskIntegrationTest < TestHelper
  def setup
    Heathrow.store = store = Redis.new(:db => 13)
    store.flushdb
  end

  test "test using sample repository" do
    with_sample_repo do
      with_repository do
        task = old_task = Heathrow::Task.new(@sample, 'branch1')
        task.start

        task = Heathrow::Queue.local_fetch_queue.next
        assert_equal old_task.id, task.id

        task.git_fetch

        task = Heathrow::Queue.bundle_check_queue.next
        assert_equal old_task.id, task.id

        # FIXME not done
      end
    end
  end

  private

  def with_repository
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git init -q --bare")
        raise 'git init failed' unless $?.success?
      end

      Heathrow.repository = Heathrow::Git.new(dir)
      yield
    end
  end
end