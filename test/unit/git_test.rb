require 'minitest/autorun'

require 'test_helper'
require 'heathrow/git'

class GitTest < TestHelper
  CURRENT_REPO = Dir.pwd
  BRANCH_REV = '4cb89478771aac41558c49eed3ff39cfa0b942d0'
  TAGGED_REV = ''

  test "local repository is considered local" do
    assert Heathrow::Git.repo_local?('/path/to/foo')
  end

  test "remote repository is considered remote" do
    assert !Heathrow::Git.repo_local?('git@github.com:/path/to/repo')
    assert !Heathrow::Git.repo_local?('git://example.com/path/to/repo.git/')
  end

  test "initialize handles regular repository" do
    with_git_repo {}
  end

  test "initialize handles bare repository" do
    with_bare_git_repo {}
  end

  test "initialize fails on non-repository" do
    Dir.mktmpdir do |dir|
      assert_raises ArgumentError do
        Heathrow::Git.new(dir)
      end
    end
  end

  test "remote_name_for gives local hashed name for local repos" do
    name1 = Heathrow::Git.remote_name_for("/foo/bar")
    name2 = Heathrow::Git.remote_name_for("/foo/baz")
    assert_match /^local-[0-9a-f]+$/, name1
    assert_match /^local-[0-9a-f]+$/, name2
    assert name1 != name2
  end

  test "remote_name_for gives remote hashed name for remote repos" do
    name1 = Heathrow::Git.remote_name_for("host:/foo/bar")
    name2 = Heathrow::Git.remote_name_for("git@github.com:/foo/baz")
    assert_match /^remote-[0-9a-f]+$/, name1
    assert_match /^remote-[0-9a-f]+$/, name2
    assert name1 != name2
  end

  test "fetch_repo fetches from repository" do
    with_git_repo do
      remote_name = Heathrow::Git.remote_name_for(CURRENT_REPO)
      in_git_repo("git remote add #{remote_name} #{CURRENT_REPO}")
      assert $?.success?

      @git.fetch_repo(CURRENT_REPO)

      in_git_repo("git rev-parse --verify -q #{KNOWN_COMMIT} > /dev/null")
      assert $?.success?
    end
  end

  private

  def with_git_repo(bare = false)
    Dir.mktmpdir do |dir|
      @path = dir
      in_git_repo("git init -q #{bare ? '--bare' : ''}")

      @git = Heathrow::Git.new(dir)
      Dir.chdir('/') { yield }
    end
  end

  def with_bare_git_repo(&block)
    with_git_repo(true, &block)
  end

  def in_git_repo(*command)
    Dir.chdir(@path) do
      system(*command)
    end
  end
end
