require 'minitest/autorun'

require 'test_helper'
require 'heathrow'

class HeathrowTest < TestHelper
  def setup
    Heathrow.store = nil
    Heathrow.repository = nil
    Heathrow.bundle_check_tree = nil
  end

  test "store defaults to Redis" do
    assert_kind_of Redis, Heathrow.store
  end

  test "store can be overridden" do
    Heathrow.store = :my_store
    assert_equal :my_store, Heathrow.store
  end

  test "repository raises error if not set" do
    assert_raises Heathrow::ConfigError do
      Heathrow.repository
    end
  end

  test "repository can be set" do
    Heathrow.repository = :repo
    assert_equal :repo, Heathrow.repository
  end

  test "bundle_check_tree raises error if not set" do
    assert_raises Heathrow::ConfigError do
      Heathrow.bundle_check_tree
    end
  end

  test "bundle_check_tree can be set" do
    Heathrow.bundle_check_tree = tree = Heathrow::Tree.new('/nonexistent')
    assert_equal tree, Heathrow.bundle_check_tree
  end
end
