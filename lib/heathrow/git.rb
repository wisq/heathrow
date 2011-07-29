require 'heathrow'

class Heathrow::Git
  def self.repo_local?(repo)
    repo.start_with?('/')
  end
end
