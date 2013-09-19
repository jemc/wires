$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe "wires/convenience" do
  
  describe "#fire" do
    it "is an alias for Channel.fire under default kwargs" do
      it_happened = false
      on Wires::Event, self do
        it_happened = true
      end
      
      fire Wires::Event, self
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "accepts an actual Channel object as its channel argument" do
      chan = Wires::Channel.new(self)
      it_happened = false
      on Wires::Event, chan do
        it_happened = true
      end
      
      fire Wires::Event, chan
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "is an alias for TimeScheduler.add if given :time kwarg" do
      it_happened = false
      on Wires::Event, self do
        it_happened = true
      end
      
      fire Wires::Event, self, time:0.1.seconds.from_now
      
      sleep 0.05
      it_happened.must_equal false
      sleep 0.10
      it_happened.must_equal true
      
      Wires::Hub.join_children
    end
    
    it "is an alias for TimeScheduler.add if given :count kwarg" do
      count = 0
      on :wolf, self do
        count+=1
      end
      sleep 0.2
      fire :wolf, self, count:50
      sleep 0.2
      Wires::Hub.join_children
      fire :thing2, self, count:50
      count.must_equal 50
    end
  end
  
  describe "#fire_and_wait" do
    it "is an alias for fire with blocking kwarg set to true" do
      count = 0
      on Wires::Event, self do
        count+=1
      end
      
      fire_and_wait Wires::Event, self
      count.must_equal 1
      Wires::Hub.join_children
    end
  end
  
  describe "#on" do
    it "is an alias for Channel#register, adding a firable target proc" do
      chan = Wires::Channel.new(self)
      
      it_happened = false
      on Wires::Event, self do
        it_happened = true
      end
      
      chan.fire Wires::Event
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "can accept an actual Channel object as the channel argument" do
      chan = Wires::Channel.new(self)
      
      it_happened = false
      on Wires::Event, chan do
        it_happened = true
      end
      
      chan.fire Wires::Event
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "can accept an array of channels to 'listen' on" do
      chans = [Wires::Channel.new('some_channel'),
               Wires::Channel.new('some_other_channel'),
               Wires::Channel.new(:some_symbol_named_channel),
               Wires::Channel.new(5083489893)]
      
      count = 0
      
      on Wires::Event, chans do
        count+=1
      end
      
      for chan in chans
        chan.fire Wires::Event
      end
      Wires::Hub.join_children
      
      count.must_equal chans.size
    end
    
    it "returns the &proc passed in" do
      proc = Proc.new { nil }
      assert_equal (on Wires::Event, self, &proc), proc
    end
    
  end
  
end