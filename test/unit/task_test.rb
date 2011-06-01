require 'minitest/autorun'

require 'test_helper'
require 'heathrow/task'

class TaskTest < TestHelper
  test "local remote is considered local" do
    context = Heathrow::Task.new('adrian_local', 'abc123')
    assert context.repo_local?
  end

  test "other remote is considered remote" do
    context = Heathrow::Task.new('adrian', 'abc123')
    assert !context.repo_local?
  end

  test "id is a UUID" do
    uuids = (1..100).map { Heathrow::Task.new('adrian', 'abc123').id }
    assert_equal uuids, uuids.uniq
  end
end
