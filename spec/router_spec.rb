$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe Wires::Router::Default do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router.clear_channels
  end
  
  it ""
  
end


describe Wires::Router::Simple do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router = Wires::Router::Simple
    Wires::Channel.router.clear_channels
  end
  
  def teardown
    Wires::Channel.router.clear_channels
    Wires::Channel.router = Wires::Router::Default
  end
  
  it "routes only on exact object matches" do
    channels = ['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                 self,        Object.new, Hash.new].map {|x| Wires::Channel[x]}
    
    channels.each { |x| x.receivers.must_equal [x] }
  end
  
end