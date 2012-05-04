require 'minitest/autorun'

require 'test_helper'
require 'heathrow/task'
require 'heathrow/client'

class TaskIntegrationTest < TestHelper
  def setup
    Heathrow.store = store = Redis.new(:db => 13)
    store.flushdb
  end

  test "test using sample repository" do
    with_sample_repo do
      with_repository do
        client = Heathrow::Client.new('user1')

        task = old_task = Heathrow::Task.new(client, @sample, 'master', 'sample:success')
        task.start

        task = Heathrow::Queue.local_fetch_queue.next
        assert_equal old_task.id, task.id

        task.git_fetch

        task = Heathrow::Queue.bundle_check_queue.next
        assert_equal old_task.id, task.id

        with_bundle_check_tree do
          task.bundle_check
        end

        with_test_tree do
          task.run_test
        end

        # FIXME not done
      end
    end
  end

  private

  def with_repository
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system('git init -q --bare')
        raise 'git init failed' unless $?.success?
      end

      Heathrow.repository = Heathrow::Git.new(dir)
      yield
    end
  ensure
    Heathrow.repository = nil
  end

  def with_bundle_check_tree
    Dir.mktmpdir do |dir|
      Heathrow.bundle_check_tree = tree = Heathrow::Tree.new(dir)
      tree.run('git init -q')
      yield
    end
  ensure
    Heathrow.bundle_check_tree = nil
  end

  def with_test_tree
    Dir.mktmpdir do |dir|
      Heathrow.test_tree = tree = Heathrow::Tree.new(dir)
      tree.run('git init -q')
      yield
    end
  ensure
    Heathrow.test_tree = nil
  end
end
