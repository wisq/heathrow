require 'heathrow'

require 'grit'
require 'digest/sha1'

class Heathrow::Git
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

  def fetch_repo(repo)
    remote = self.class.remote_name_for(repo)
    @tree.run('git', 'fetch', '-q', remote)
  end
end
