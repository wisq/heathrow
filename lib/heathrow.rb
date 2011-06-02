require 'bundler/setup'
require 'redis'

module Heathrow
  class << self
    attr_accessor :store

    def store
      @store ||= Redis.new
    end
  end
end

require 'heathrow/task'
