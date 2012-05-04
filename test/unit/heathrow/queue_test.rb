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

  test "#next clears current task, block-retrieves next task, and sets it as current" do
    sequence = sequence('del_pop_set')
    @store.expects(:del  ).in_sequence(sequence).with('queue:bundle_check:current')
    @store.expects(:blpop).in_sequence(sequence).with('queue:bundle_check', 0).returns(['queue:bundle_check', '123abc'])
    @store.expects(:set  ).in_sequence(sequence).with('queue:bundle_check:current', '123abc')
    Heathrow::Task.expects(:find).with('123abc').returns(task = mock(:id => '123abc'))

    assert_equal task, Heathrow::Queue.bundle_check_queue.next
  end

  test "#notify_client sends message to selected client based on position" do
    client1 = stub(:id => 'c1', :username => 'person1')
    client2 = stub(:id => 'c2', :username => 'person2')
    client3 = stub(:id => 'c3')
    Heathrow::Task.expects(:find).with('123abc').returns(mock(:client => client1))
    Heathrow::Task.expects(:find).with('456def').returns(mock(:client => client2))
    Heathrow::Task.expects(:find).with('789fff').returns(mock(:client => client3))

    @store.expects(:get).with('queue:bundle_check:current').returns('123abc')
    @store.expects(:lrange).with('queue:bundle_check', 0, -1).returns(['456def', '789fff'])

    client3.expects(:<<).with("You are #2 in line for bundle checking.  (Ahead of you: person2, person1.)")

    Heathrow::Queue.bundle_check_queue.notify_client(client3, "bundle checking")
  end

  test "#notify_pending sends message to all waiting clients based on position" do
    client1 = stub(:username => 'person1')
    client2 = stub(:username => 'person2')
    client3 = stub(:username => 'person3')
    Heathrow::Task.expects(:find).with('123abc').returns(stub(:id => '123abc', :client => client1))
    Heathrow::Task.expects(:find).with('456def').returns(stub(:id => '456def', :client => client2))
    Heathrow::Task.expects(:find).with('789fff').returns(stub(:id => '789fff', :client => client3))

    @store.expects(:get).with('queue:test:current').at_least_once.returns('123abc')
    @store.expects(:lrange).with('queue:test', 0, -1).returns(['456def', '789fff'])

    client1.expects(:<<).never
    client2.expects(:<<).with("You are #1 in line for testing.  (Ahead of you: person1.)")
    client3.expects(:<<).with("You are #2 in line for testing.  (Ahead of you: person2, person1.)")
    Heathrow::Queue.test_queue.notify_pending("testing")
  end
end
