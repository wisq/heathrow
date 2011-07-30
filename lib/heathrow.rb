require 'redis'

module Heathrow
  class ConfigError < StandardError; end

  class << self
    attr_writer :store, :repository, :bundle_check_tree

    def store
      @store ||= Redis.new
    end

    def repository
      @repository or raise ConfigError, "No repository set"
    end

    def bundle_check_tree
      @bundle_check_tree or raise ConfigError, "No 'bundle check' tree set"
    end
  end
end

require 'heathrow/task'
require 'heathrow/git'
require 'heathrow/tree'
