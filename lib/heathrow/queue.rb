require 'heathrow'

require 'redis'

class Heathrow::Queue
  @@queues = {}

  def self.define_queue(name)
    @@queues[name] = new
    self.class.instance_eval { define_method("#{name}_queue".to_sym) { @@queues[name] } }
  end

  [:remote_fetch, :local_fetch, :bundle_check, :bundle_install, :test].each { |q| define_queue(q) }
end
