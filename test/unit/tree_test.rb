require 'minitest/autorun'

require 'test_helper'
require 'heathrow/tree'

require 'tmpdir'

class TreeTest < TestHelper
  test "run changes to directory and runs command" do
    with_tree do
      @tree.run('touch', 'file1', 'file2')

      assert File.exist?("#{@path}/file1")
      assert File.exist?("#{@path}/file2")
    end
  end

  test "run raises exception on command failure" do
    assert_raises Heathrow::Tree::CommandFailed do
      with_tree { @tree.run('/bin/false') }
    end
  end

  private

  def with_tree
    Dir.mktmpdir do |dir|
      @tree = Heathrow::Tree.new(dir)
      @path = dir
      yield
    end
  end
end
