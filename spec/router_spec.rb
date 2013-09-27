$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end

require 'set' # for order-less comparison of arrays


describe Wires::Router::Default do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router.clear_channels
  end
  
  it "routes on exact object matches for all objects but Regexp/String pairs;"\
     " it also routes all channels to the '*' receiver channel" do
    channels = ['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                 self,        Object.new, Hash.new].map {|x| Wires::Channel[x]}
    
    channels.each do |channel|
      receivers = [channel, Wires::Channel['*']]
      receivers << channels.select do |x| 
        x.name.is_a? Regexp and \
          (begin; x.name=~channel.name; rescue TypeError; end)
      end
      channel.receivers.to_set.must_equal receivers.flatten.to_set
    end
  end
  
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
    
    channels.each { |c| c.receivers.must_equal [c] }
  end
  
end