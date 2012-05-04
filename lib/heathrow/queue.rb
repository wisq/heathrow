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
    store = Heathrow.store
    store.del(current_key)
    task = Heathrow::Task.find(Heathrow.store.blpop(redis_key, 0).last)
    store.set(current_key, task.id)
    task
  end

  def notify_client(client, action, ahead = nil)
    ahead ||= all_tasks.map(&:client).take_while { |c| c.id != client.id }.map(&:username).reverse
    client << "You are ##{ahead.count} in line for #{action}.  (Ahead of you: #{ahead.join(', ')}.)"
  end

  def notify_pending(action)
    current = Heathrow.store.get(current_key)
    ahead = []

    all_tasks.each do |task|
      notify_client(task.client, action, ahead) unless task.id == current
      ahead.unshift(task.client.username)
    end
  end

  def all_tasks
    current = Heathrow.store.get(current_key)
    pending = Heathrow.store.lrange(redis_key, 0, -1)
    users = ([current] + pending).compact.map { |id| Heathrow::Task.find(id) }
  end

  private

  def redis_key
    "queue:#{id}"
  end

  def current_key
    "#{redis_key}:current"
  end
end
