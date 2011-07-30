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
        task = Heathrow::Task.new(@sample, 'branch1')
        task.start

        old_task = task
        task = Heathrow::Queue.local_fetch_queue.next
        assert_equal old_task.id, task.id

        skip 'not ready yet'
        task.git_fetch
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
