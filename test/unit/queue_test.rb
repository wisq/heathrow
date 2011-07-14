require 'minitest/autorun'

require 'test_helper'
require 'heathrow/queue'

class QueueTest < TestHelper
  def setup
    @store = Heathrow.store = mock
  end

  test "queues can be fetched from class" do
    assert_equal :bundle_check, Heathrow::Queue.bundle_check_queue.id
    assert_equal :test,         Heathrow::Queue.test_queue.id
  end

  test "#<< saves a task and stores the ID" do
    task = mock(:id => 'abc123', :save => nil)
    @store.expects(:rpush).with('queue:test', 'abc123')

    Heathrow::Queue.test_queue << task
  end

  test "#next blocks and retrieves the next task" do
    @store.expects(:blpop).with('queue:bundle_check', 0).returns(['queue:bundle_check', '123abc'])
    Heathrow::Task.expects(:find).with('123abc').returns(task = mock)

    assert_equal task, Heathrow::Queue.bundle_check_queue.next
  end
end
