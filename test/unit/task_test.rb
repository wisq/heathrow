require 'minitest/autorun'

require 'test_helper'
require 'heathrow/task'

class TaskTest < TestHelper
  def setup
    @task  = Heathrow::Task.new('foo', 'abc123')
    @store = Heathrow.store = mock
  end

  test "local remote is considered local" do
    task = Heathrow::Task.new('foo_local', 'abc123')
    assert task.repo_local?
  end

  test "other remote is considered remote" do
    task = Heathrow::Task.new('foo', 'abc123')
    assert !task.repo_local?
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
end
