require 'wires'
# require_relative '../spec/wires-devel'

require 'minitest/autorun'
require 'minitest/spec'
require 'turn'
Turn.config.format  = :outline
Turn.config.natural = true
Turn.config.trace   = 5

# Define SysHub
class SysHub < Wires::Hub; end

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

def SysChannel(*args)
  SysChannel.new(*args)
end


describe 'distinct-wires.rb' do
  
  it "allows the creation of a distinct wires system through inheritance" do
    data = []
    
    # Test of distinct Hub system
    class MyCoolEvent < Wires::Event; end
    Wires::Hub.run
    SysHub.run

    on :my_cool do data << "hola" end
    sys_on :my_cool do data << "holaback" end

    fire(:my_cool)
    sys_fire(:my_cool)

    Wires::Hub.kill
    SysHub.kill
    
    data.must_include "hola"
    data.must_include "holaback"
    data.size.must_equal 2
    
  end
  
end