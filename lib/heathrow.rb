require 'redis'

module Heathrow
  class << self
    attr_accessor :store, :repository

    def store
      @store ||= Redis.new
    end
  end
end

require 'heathrow/task'
require 'heathrow/git'
require 'heathrow/tree'
