require 'heathrow'

class Heathrow::Tree
  class CommandFailed < StandardError; end

  def initialize(path)
    @path = path
  end

  def run(command, *args)
    Dir.chdir(@path) do
      system(command, *args)
      raise CommandFailed unless $?.success?
    end
  end
end
