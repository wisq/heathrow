require 'heathrow'

class Heathrow::Queue
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

  def initialize(id)
    @id = id
  end

  def <<(task)
    task.save
    Heathrow.store.rpush(redis_key, task.id)
  end

  def next
    Heathrow::Task.find(Heathrow.store.blpop(redis_key, 0).last)
  end

  def redis_key
    "queue:#{id}"
  end
end
