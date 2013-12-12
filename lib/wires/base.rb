
require 'thread'
require 'threadlock'


module Wires
  def self.network(id=:main)
    @networks ||= {main:Module.new}
    
    unless @networks.has_key? id
      @networks[id] = Module.new
      @networks[id].const_set :Namespace, Module.new
    end
    
    @networks[id]
  end
  
  def self.set_current_network(*args)
    @current_network = network(*args)
  end
  
  def self.current_network
    @current_network ||= network
  end
  
  def self.const_missing *args
    self.current_network::Namespace.const_get *args
  end
end


loader = Proc.new do |path|
  load File.expand_path(path+'.rb', File.dirname(__FILE__))
end

loader.call 'base/util/hooks'
loader.call 'base/util/build_alt'

loader.call 'base/event'
loader.call 'base/hub'
loader.call 'base/router'
loader.call 'base/channel'
loader.call 'base/time_scheduler_item'
loader.call 'base/time_scheduler'
loader.call 'base/convenience'
