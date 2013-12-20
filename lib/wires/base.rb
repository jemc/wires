
require 'thread'
require 'threadlock'


module Wires
  def self.network(id=:main)
    @networks ||= {main:Wires}
    
    unless @networks.has_key? id
      @networks[id] = Module.new
    end
    
    unless @networks[id].const_defined? :Namespace
      @networks[id].const_set :Namespace, @networks[id]
    end
    
    @networks[id]
  end
  
  def self.set_current_network(*args)
    @current_network = network(*args)
  end
  
  def self.current_network_name
    @networks.each_pair.select{ |k,v| v==@current_network }.first.first
  end
  
  def self.current_network
    @current_network ||= network
  end
  
  def self.replicate
    save_name = Wires.current_network_name
    other = Wires.set_current_network Object.new
    
    load __FILE__
    
    Wires.set_current_network save_name
    return other
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
