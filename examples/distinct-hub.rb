require 'wires'

# require 'minitest/spec'
# require 'minitest/autorun'

# Define SysHub
SysHub = Wires::Hub.clone

# Define SysChannel
class SysChannel < Wires::Channel
  def self.hub; SysHub; end
end

# SysChannel versions of Channel convenience functions
def sys_on(events, channels='*', &codeblock)
  channels = [channels] unless channels.is_a? Array
  for channel in channels
    SysChannel.new(channel).register(events, codeblock)
  end
nil end

def sys_fire(event, channel='*') 
  SysChannel.new(channel).fire(event, blocking:false)
nil end

def sys_fire_and_wait(event, channel='*') 
  SysChannel.new(channel).fire(event, blocking:true)
nil end

def SysChannel(*args) SysChannel.new(*args) end



# Test of distinct Hub system
class MyCoolEvent < Wires::Event; end
Wires::Hub.run
SysHub.run

on :my_cool do puts "hola" end
sys_on :my_cool do puts "holaback" end

fire(:my_cool)
sys_fire(:my_cool)

Wires::Hub.kill :blocking, :finish_all
SysHub.kill     :blocking, :finish_all