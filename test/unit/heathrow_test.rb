require 'minitest/autorun'

require 'test_helper'
require 'heathrow'

class QueueTest < TestHelper
  def setup
    Heathrow.store = nil
  end

  test "store defaults to Redis" do
    assert_kind_of Redis, Heathrow.store
  end

  test "store can be overridden" do
    Heathrow.store = :my_store
    assert_equal :my_store, Heathrow.store
  end
end
