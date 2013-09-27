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
  
  it "routes on exact object matches for all objects but Regexp/String pairs"\
     " and routes all channels to the '*' receiver" do
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
  
  it "routes the '*' channel to all receivers" do
    channels = ['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                 self,        Object.new, Hash.new].map {|x| Wires::Channel[x]}
    
    channels.each do |channel|
      Wires::Channel['*'].receivers.must_include channel
    end
  end
  
  it "asserts that Regexp channels are not firable" do
    channels = ['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                 self,        Object.new, Hash.new].map {|x| Wires::Channel[x]}
    
    channels.each do |x|
      if x.name.is_a? Regexp
        x.not_firable.wont_be_nil             "bad chan: #{x.inspect}"
        x.not_firable.must_include TypeError, "bad chan: #{x.inspect}"
      else
        x.not_firable.must_be_nil             "bad chan: #{x.inspect}"
      end
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