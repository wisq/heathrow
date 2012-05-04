require 'heathrow'
require 'heathrow/base'

class Heathrow::Client < Heathrow::Base
  attr_reader :id, :username

  def initialize(username)
    @id = generate_id
    @username = username
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

  def read_nonblock
    Heathrow.store.lpop(output_key)
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
