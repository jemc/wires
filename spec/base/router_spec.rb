
require 'spec_helper'


describe Wires::Router do
  
  let(:names) { ['channel',   'Channel',  'CHANNEL',
                 :channel,    :Channel,   :CHANNEL,
                 /channel/,   /Channel/,  /CHANNEL/,
                ['channel'], [:channel], [/channel/],
                 self,        Object.new, Hash.new] }
  let(:channels) { names.map{|x| Wires::Channel[x]}.to_a }
  
  
  describe Wires::Router::Default do
    before { Wires::Channel.router = Wires::Router::Default
             Wires::Channel.router.clear_channels }
    
    it "routes on exact object matches for all objects but Regexp/String pairs"\
       " and routes all channels to the '*' receiver" do
      channels.each do |channel|
        receivers = [channel, Wires::Channel['*']]
        receivers += channels.select do |c| 
          c.name.is_a? Regexp and \
            (begin; c.name=~channel.name; rescue TypeError; end)
        end
        expect(channel.receivers).to match_array receivers
      end
    end
    
    it "routes the '*' channel to all receivers" do
      channels.each do |channel|
        expect(Wires::Channel['*'].receivers).to include channel
      end
    end
    
    it "asserts that Regexp channels are not firable" do
      channels.each do |channel|
        if channel.name.is_a? Regexp
          expect(channel.not_firable).to be
          expect(channel.not_firable).to include TypeError
        else
          expect(channel.not_firable).to_not be
        end
      end
    end
    
    it "can forget channels by name" do
      names.each do |n|
        a = Wires::Channel[n]; Wires::Channel.forget n
        b = Wires::Channel[n]
        expect(a).not_to equal b
      end
    end
  end


  describe Wires::Router::Simple do
    before do
      Wires::Channel.router = Wires::Router::Simple
      Wires::Channel.router.clear_channels
    end
    
    after do
      Wires::Channel.router.clear_channels
      Wires::Channel.router = Wires::Router::Default
    end
    
    it "routes only on exact object matches" do
      channels.each { |c| expect(c.receivers).to match_array [c] }
    end
    
    it "can forget channels by name" do
      names.each do |n|
        a=Wires::Channel[n]; Wires::Channel.forget n
        b=Wires::Channel[n]
        expect(a).not_to equal b
      end
    end
  end
  
end