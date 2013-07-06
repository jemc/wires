require 'wires'

# require 'minitest/spec'
# require 'minitest/autorun'

# Define SysHub
SysHub = Hub.clone

# Define SysChannel
class SysChannel < Channel
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
