require 'heathrow'
require 'heathrow/base'

class Heathrow::Client < Heathrow::Base
  @@queues = {}

  def self.define_queue(id)
    self.class.instance_eval do
      define_method("#{id}_queue".to_sym) do
        @@queues[id] ||= new(id)
      end
    end
  end

  [:remote_fetch, :local_fetch, :bundle_check, :bundle_install, :test].each { |q| define_queue(q) }

  attr_reader :id

  def initialize(id = generate_id)
    @id = id
  end

  def <<(output)
    Heathrow.store.rpush(output_key, output)
  end

  def read
    key, value = Heathrow.store.blpop(control_key, output_key, 0)

    case key
    when output_key
      return value
    when control_key
      process_control(value)
    else
      raise "Unexpected key: #{key.inspect}"
    end
  end

  def close
    control(:close)
  end

  private

  def process_control(command)
    case command.to_sym
    when :close
      raise EOFError
    else
      raise "Unexpected control command: #{command.inspect}"
    end
  end

  def control(command)
    Heathrow.store.rpush(control_key, command.to_s)
  end

  def output_key
    "client:#{id}:output"
  end

  def control_key
    "client:#{id}:control"
  end
end
