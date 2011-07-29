require 'minitest/autorun'

require 'test_helper'
require 'heathrow/git'

class GitTest < TestHelper
  test "local repository is considered local" do
    assert Heathrow::Git.repo_local?('/path/to/foo')
  end

  test "remote repository is considered remote" do
    assert !Heathrow::Git.repo_local?('git@github.com:/path/to/repo')
    assert !Heathrow::Git.repo_local?('git://example.com/path/to/repo.git/')
  end
end
