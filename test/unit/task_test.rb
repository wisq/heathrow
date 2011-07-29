require 'minitest/autorun'

require 'test_helper'
require 'heathrow/task'

class TaskTest < TestHelper
  def setup
    @task  = Heathrow::Task.new('/path/to/foo', 'abc123')
    @store = Heathrow.store = mock
    @repo  = Heathrow.repository = mock
  end

  test "remote is considered local by consulting Git module" do
    Heathrow::Git.expects(:repo_local?).with('/path/to/foo').returns(true)
    assert @task.repo_local?

    Heathrow::Git.expects(:repo_local?).with('git@github.com:/path/to/remote').returns(false)
    remote = Heathrow::Task.new('git@github.com:/path/to/remote', 'abc123')
    assert !remote.repo_local?
  end

  test "id is a unique ID" do
    ids = (1..100).map { Heathrow::Task.new('adrian', 'abc123').id }
    assert_equal ids, ids.uniq
  end

  test "save saves to store" do
    @task.expects(:id).returns('abc123')
    Marshal.expects(:dump).with(@task).returns('marshalled-task')
    @store.expects(:set).with('task:abc123', 'marshalled-task')

    @task.save
  end

  test "save applies unique ID before marshalling" do
    stored_id = nil
    Marshal.expects(:dump).with(@task) do |task|
      stored_id = task.dup.id
    end
    @store.stubs(:set)

    @task.save
    assert_equal @task.id, stored_id
  end

  test "find loads task from store" do
    @store.expects(:get).with('task:abc123').returns('marshalled-task')
    Marshal.expects(:load).with('marshalled-task').returns(:some_task)

    assert_equal :some_task, Heathrow::Task.find('abc123')
  end

  test "queue_remote_fetch queues task" do
    Heathrow::Queue.remote_fetch_queue.expects(:<<).with(@task)
    @task.queue_remote_fetch
  end

  test "queue_local_fetch queues task" do
    Heathrow::Queue.local_fetch_queue.expects(:<<).with(@task)
    @task.queue_local_fetch
  end

  test "queue_bundle_check queues task" do
    Heathrow::Queue.bundle_check_queue.expects(:<<).with(@task)
    @task.queue_bundle_check
  end

  test "git_fetch fetches from a repository, tags the git ID, and marks task as fetched" do
    @repo.expects(:fetch_repo).with('/path/to/foo')
    @repo.expects(:add_tag).with('abc123')
    state(@task).expects(:fetched)

    @task.git_fetch
  end

  private

  def state(task)
    task.instance_variable_get(:@state)
  end
end
