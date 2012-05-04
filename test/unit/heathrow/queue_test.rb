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

  test "#<< saves a task, stores the ID, and calls #notify_client" do
    task = mock(:id => 'abc123', :save => nil)
    @store.expects(:rpush).with('queue:test', 'abc123')

    Heathrow::Queue.test_queue.expects(:notify_client).with(task)
    Heathrow::Queue.test_queue << task
  end

  test "#next clears current task, block-retrieves next task, sets it as current, and calls #notify_pending" do
    sequence = sequence('del_pop_set')
    @store.expects(:del  ).in_sequence(sequence).with('queue:bundle_check:current')
    @store.expects(:blpop).in_sequence(sequence).with('queue:bundle_check', 0).returns(['queue:bundle_check', '123abc'])
    @store.expects(:set  ).in_sequence(sequence).with('queue:bundle_check:current', '123abc')
    Heathrow::Task.expects(:find).with('123abc').returns(task = mock(:id => '123abc'))

    Heathrow::Queue.bundle_check_queue.expects(:notify_pending)
    assert_equal task, Heathrow::Queue.bundle_check_queue.next
  end

  test "#notify_client sends message to selected client based on task state and position" do
    task1   = stub(:id => '123abc', :client => stub(:username => 'person1'), :queue_message => 'checking gems')
    task2   = stub(:id => '456def', :client => stub(:username => 'person2'), :queue_message => 'checking gems')
    task3   = stub(:id => '789fff', :client => stub(:username => 'person3'), :queue_message => 'checking gems')
    Heathrow::Task.expects(:find).with(task1.id).at_least_once.returns(task1)
    Heathrow::Task.expects(:find).with(task2.id).returns(task2)
    Heathrow::Task.expects(:find).with(task3.id).returns(task3)

    @store.expects(:get).with('queue:bundle_check:current').at_least_once.returns(task1.id)
    @store.expects(:lrange).with('queue:bundle_check', 0, -1).returns([task2.id, task3.id])

    task3.client.expects(:<<).with("You are #3 in line for checking gems.  (Ahead of you: person2, person1.)")

    Heathrow::Queue.bundle_check_queue.notify_client(task3)
  end

  test "#notify_client does not send message if client has already been picked up by a worker" do
    client = stub(:username => 'person1')
    task   = stub(:id => 'abc123', :client => client, :queue_message => 'none')

    Heathrow::Task.expects(:find).with(task.id).returns(task)
    @store.expects(:get).with('queue:local_fetch:current').returns(task.id)
    @store.expects(:lrange).never

    client.expects(:<<).never

    Heathrow::Queue.local_fetch_queue.notify_client(task)
  end

  test "#notify_client does not send message if client has already been completed" do
    client1 = stub(:username => 'person1')
    client2 = stub(:username => 'person2')
    task1   = stub(:id => '123abc', :client => client1)
    task2   = stub(:id => '456def', :client => client2)

    Heathrow::Task.expects(:find).with(task1.id).never
    Heathrow::Task.expects(:find).with(task2.id).returns(task2)
    @store.expects(:get).with('queue:local_fetch:current').at_least_once.returns(nil)
    @store.expects(:lrange).with('queue:local_fetch', 0, -1).returns([task2.id])

    client1.expects(:<<).never

    Heathrow::Queue.local_fetch_queue.notify_client(task1)
  end

  test "#notify_pending sends message to all waiting clients based on position" do
    client1 = stub(:username => 'person1')
    client2 = stub(:username => 'person2')
    client3 = stub(:username => 'person3')
    Heathrow::Task.expects(:find).with('123abc').returns(stub(:id => '123abc', :client => client1, :queue_message => 'testing'))
    Heathrow::Task.expects(:find).with('456def').returns(stub(:id => '456def', :client => client2, :queue_message => 'testing'))
    Heathrow::Task.expects(:find).with('789fff').returns(stub(:id => '789fff', :client => client3, :queue_message => 'testing'))

    @store.expects(:get).with('queue:test:current').at_least_once.returns('123abc')
    @store.expects(:lrange).with('queue:test', 0, -1).returns(['456def', '789fff'])

    client1.expects(:<<).never
    client2.expects(:<<).with("You are #2 in line for testing.  (Ahead of you: person1.)")
    client3.expects(:<<).with("You are #3 in line for testing.  (Ahead of you: person2, person1.)")
    Heathrow::Queue.test_queue.notify_pending
  end
end
