require 'minitest/autorun'

require 'test_helper'
require 'heathrow/git'

class GitTest < TestHelper
  SAMPLE_REPO = File.dirname(__FILE__) + '/../data/sample.tar'
  BRANCH_REV  = '2fe0de0e0dcf423121e0b80b01f92ed8f36e66f0'
  TAGGED_REV  = '3df0799daa917c7fe40f723146a8a839fb6ec2c4'

  def setup
    @path = @git = @sample = nil
  end

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

  test "fetch_branches fetches branches from repository" do
    with_sample_repo do
      with_git_repo do
        Heathrow::Git.expects(:remote_name_for).with(@sample).at_least_once.returns('my-remote')
        in_git_repo("git remote add my-remote #{@sample}")
        assert $?.success?

        @git.fetch_branches(@sample)

        in_git_repo("git show #{BRANCH_REV} > /dev/null 2>&1")
        assert $?.success?, "Failed to find revision #{BRANCH_REV} (branch)"

        in_git_repo("git show #{TAGGED_REV} > /dev/null 2>&1")
        assert !$?.success?, "Did not expect to find revision #{TAGGED_REV} (tagged)"
      end
    end
  end

  test "fetch_tags fetches tags from repository" do
    with_sample_repo do
      with_git_repo do
        Heathrow::Git.expects(:remote_name_for).with(@sample).at_least_once.returns('my-remote')
        in_git_repo("git remote add my-remote #{@sample}")
        assert $?.success?

        @git.fetch_tags(@sample)

        in_git_repo("git show #{TAGGED_REV} > /dev/null 2>&1")
        assert $?.success?, "Failed to find revision #{TAGGED_REV} (tagged)"

        in_git_repo("git show #{BRANCH_REV} > /dev/null 2>&1")
        assert !$?.success?, "Did not expect to find revision #{BRANCH_REV} (branch)"
      end
    end
  end

  private

  def with_sample_repo
    Dir.mktmpdir do |dir|
      system('tar', '-xf', SAMPLE_REPO, '-C', dir, '--strip-components=1')
      raise 'tar failed' unless $?.success?

      @sample = dir
      yield
    end
  end

  def with_git_repo(bare = false)
    Dir.mktmpdir do |dir|
      @path = dir
      in_git_repo("git init -q #{bare ? '--bare' : ''}")
      raise 'git init failed' unless $?.success?

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

  def in_sample_repo(*command)
    Dir.chdir(@sample) do
      system(*command)
    end
  end
end
