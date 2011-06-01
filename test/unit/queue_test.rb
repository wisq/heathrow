require 'minitest/autorun'

require 'test_helper'
require 'heathrow/queue'

class QueueTest < TestHelper
  test "queues can be fetched from class" do
    assert Heathrow::Queue.bundle_check_queue
    assert Heathrow::Queue.test_queue
  end
end
