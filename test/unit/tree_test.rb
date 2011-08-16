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

  test "git creates Git object using tree" do
    with_tree do
      Heathrow::Git.expects(:new).with(@tree).returns(git = mock)
      assert_equal git, @tree.git
    end
  end

  test "git memoises Git object" do
    with_tree do
      Heathrow::Git.expects(:new).once.with(@tree).returns(git = mock)
      assert_equal git, @tree.git
      assert_equal git, @tree.git
    end
  end

  private

  def with_tree
    Dir.mktmpdir do |dir|
      @tree = Heathrow::Tree.new(dir)
      @path = dir
      Dir.chdir('/') { yield }
    end
  end
end
