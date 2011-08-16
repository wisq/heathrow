require 'heathrow'

class Heathrow::Tree
  class CommandFailed < StandardError; end

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def run(command, *args)
    Dir.chdir(@path) do
      system(command, *args)
      raise CommandFailed unless $?.success?
    end
  end

  def git
    @git ||= Heathrow::Git.new(self)
  end
end
