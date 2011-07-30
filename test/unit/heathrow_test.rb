require 'minitest/autorun'

require 'test_helper'
require 'heathrow'

class HeathrowTest < TestHelper
  def setup
    Heathrow.store = nil
    Heathrow.repository = nil
  end

  test "store defaults to Redis" do
    assert_kind_of Redis, Heathrow.store
  end

  test "store can be overridden" do
    Heathrow.store = :my_store
    assert_equal :my_store, Heathrow.store
  end

  test "repository has no default" do
    assert Heathrow.repository.nil?
  end

  test "repository can be set" do
    repo = mock
    Heathrow.repository = repo
    assert_equal repo, Heathrow.repository
  end
end
