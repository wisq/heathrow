require 'heathrow'

require 'grit'
require 'digest/sha1'

class Heathrow::Git
  class RepositoryMismatch < StandardError; end

  def self.repo_local?(repo)
    repo.start_with?('/')
  end

  def self.remote_name_for(repo)
    (repo_local?(repo) ? 'local' : 'remote') + '-' + Digest::SHA1.hexdigest(repo)
  end

  def initialize(path)
    @tree = Heathrow::Tree.new(path)

    if File.directory?("#{path}/.git/objects")
      @repo = Grit::Repo.new(path)
    elsif File.directory?("#{path}/objects")
      @repo = Grit::Repo.new(path, :is_bare => true)
    else
      raise ArgumentError, "Not a git repository: #{path}"
    end
  end

  def fetch_branches(repo)
    fetch_from_repo(repo, [])
  end

  def fetch_tags(repo)
    fetch_from_repo(repo, ['-t'])
  end

  def tag_remote_branch(name, repo, branch)
    remote = self.class.remote_name_for(repo)
    @tree.run('git', 'tag', name, "#{remote}/#{branch}")
  end

  private

  def fetch_from_repo(repo, options)
    remote   = self.class.remote_name_for(repo)
    existing = @repo.config["remote.#{remote}.url"]

    if existing.nil?
      @tree.run('git', 'remote', 'add', remote, repo)
    elsif existing != repo
      raise RepositoryMismatch, "Remote #{remote}: Expected #{repo.inspect}, got #{existing.inspect}"
    end

    @tree.run('git', 'fetch', '-q', remote, *options)
  end
end
