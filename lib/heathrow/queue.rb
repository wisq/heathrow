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
    notify_client(task)
  end

  def next
    store = Heathrow.store
    store.del(current_key)
    task = Heathrow::Task.find(Heathrow.store.blpop(redis_key, 0).last)
    store.set(current_key, task.id)
    notify_pending
    task
  end

  def notify_client(task, ahead = nil)
    if ahead.nil?
      return if task == current_task

      tasks = all_tasks
      ahead = tasks.take_while { |t| t != task }.map(&:client).map(&:username).reverse
      return if tasks.count == ahead.count # we're not in all_tasks; already completed?
    end

    task.client << "You are ##{ahead.count + 1} in line for #{task.queue_message}.  (Ahead of you: #{ahead.join(', ')}.)"
  end

  def notify_pending
    ahead   = []
    current = current_task
    ahead << current.client.username if current

    pending_tasks.each do |task|
      notify_client(task, ahead)
      ahead.unshift(task.client.username)
    end
  end

  private

  def redis_key
    "queue:#{id}"
  end

  def current_key
    "#{redis_key}:current"
  end

  def all_tasks
    ([current_task] + pending_tasks).compact
  end

  def current_task
    id = Heathrow.store.get(current_key)
    return nil if id.nil?
    Heathrow::Task.find(id)
  end

  def pending_tasks
    Heathrow.store.lrange(redis_key, 0, -1).map { |id| Heathrow::Task.find(id) }
  end
end
