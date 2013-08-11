$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe "wires/convenience" do
  
  describe "#Channel" do
    it "is an alias for Channel.new" do
      Wires::Channel.new('new').must_equal Channel('new')
    end
  end
  
  describe "#on" do
    it "is an alias for Channel#register, adding a firable target proc" do
      chan = Wires::Channel.new('channel')
      
      it_happened = false
      on :event, 'channel' do
        it_happened = true
      end
      
      Wires::Hub.run
      chan.fire :event
      Wires::Hub.kill
      
      it_happened.must_equal true
    end
    
    it "can accept an actual Channel object as the channel argument" do
      chan = Wires::Channel.new('some_channel')
      
      it_happened = false
      on :event, chan do
        it_happened = true
      end
      
      Wires::Hub.run
      chan.fire :event
      Wires::Hub.kill
      
      it_happened.must_equal true
    end
    
    it "can accept an array of channels to 'listen' on" do
      chans = [Wires::Channel.new('some_channel'),
               Wires::Channel.new('some_other_channel'),
               Wires::Channel.new(:some_symbol_named_channel),
               Wires::Channel.new(5083489893)]
      
      count = 0
      
      for chan in chans
        on :event, chan do
          count+=1
        end
      end
      
      Wires::Hub.run
      for chan in chans
        chan.fire :event
      end
      Wires::Hub.kill
      
      count.must_equal chans.size
    end
  end
  
end