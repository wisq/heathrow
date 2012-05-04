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

  test "#current_task fetches current task from store" do
    task = stub_task(1)

    @store.expects(:get).with('queue:bundle_check:current').returns(task.id)
    Heathrow::Task.expects(:find).with(task.id).returns(task)

    assert_equal task, Heathrow::Queue.bundle_check_queue.current_task
  end

  test "#pending_tasks fetches all pending tasks from store" do
    task1, task2, task3 = stub_tasks(3)

    @store.expects(:lrange).with('queue:bundle_check', 0, -1).returns([task1.id, task2.id, task3.id])
    Heathrow::Task.expects(:find).with(task1.id).returns(task1)
    Heathrow::Task.expects(:find).with(task2.id).returns(task2)
    Heathrow::Task.expects(:find).with(task3.id).returns(task3)

    assert_equal [task1, task2, task3], Heathrow::Queue.bundle_check_queue.pending_tasks
  end

  test "#notify_client sends message to selected client based on task state and position" do
    @queue_message = 'checking gems'
    task1, task2, task3 = stub_tasks(3)

    with_queue(:bundle_check, task1, [task2, task3]) do |queue|
      task3.client.expects(:<<).with("You are #3 in line for checking gems.  (Ahead of you: person2, person1.)")
      queue.notify_client(task3)
    end
  end

  test "#notify_client does not send message if client has already been picked up by a worker" do
    task1, task2, task3 = stub_tasks(3)

    with_queue(:local_fetch, task1, [task2, task3]) do |queue|
      task1.client.expects(:<<).never
      queue.notify_client(task1)
    end

  end

  test "#notify_client does not send message if client has already been completed" do
    task1, task2, task3 = stub_tasks(3)

    with_queue(:local_fetch, task2, [task3]) do |queue|
      task1.client.expects(:<<).never
      queue.notify_client(task1)
    end
  end

  test "#notify_pending sends message to all waiting clients based on position" do
    @queue_message = 'testing'
    task1, task2, task3 = stub_tasks(3)

    with_queue(:test, task1, [task2, task3]) do |queue|
      task1.client.expects(:<<).never
      task2.client.expects(:<<).with("You are #2 in line for testing.  (Ahead of you: person1.)")
      task3.client.expects(:<<).with("You are #3 in line for testing.  (Ahead of you: person2, person1.)")
      queue.notify_pending
    end
  end

  private

  def with_queue(name, current, pending)
    queue = Heathrow::Queue.send("#{name}_queue".to_sym)
    queue.stubs(:current_task).returns(current)
    queue.stubs(:pending_tasks).returns(pending)
    yield queue
  end

  def stub_task(number)
    client = stub(:username => "person#{number}")
    stub(
      :id => "task#{number}",
      :client => client,
      :queue_message => @queue_message
    )
  end

  def stub_tasks(count)
    (1..count).map { |i| stub_task(i) }
  end
end
