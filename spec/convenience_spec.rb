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
  
  describe "#fire" do
    it "is an alias for Channel.fire under default kwargs" do
      it_happened = false
      on :event, 'convenience_fire_A' do
        it_happened = true
      end
      
      fire :event, 'convenience_fire_A'
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "accepts an actual Channel object as its channel argument" do
      chan = Wires::Channel.new('convenience_fire_B')
      it_happened = false
      on :event, chan do
        it_happened = true
      end
      
      fire :event, chan
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "is an alias for TimeScheduler.add if given :time kwarg" do
      it_happened = false
      on :event, 'convenience_fire_C' do
        it_happened = true
      end
      
      fire :event, 'convenience_fire_C', time:0.1.seconds.from_now
      
      sleep 0.05
      it_happened.must_equal false
      sleep 0.10
      it_happened.must_equal true
      
      Wires::Hub.join_children
    end
    
    it "is an alias for TimeScheduler.add if given :count kwarg" do
      count = 0
      on :event, 'convenience_fire_D' do
        count+=1
      end
      
      fire :event, 'convenience_fire_D', count:50, blocking:true
      count.must_equal 50
      Wires::Hub.join_children
    end
  end
  
  describe "#fire_and_wait" do
    it "is an alias for fire with blocking kwarg set to true" do
      count = 0
      on :event, 'convenience_fire_and_wait_A' do
        count+=1
      end
      
      fire_and_wait :event, 'convenience_fire_and_wait_A', count:50
      count.must_equal 50
      Wires::Hub.join_children
    end
  end
  
  describe "#on" do
    it "is an alias for Channel#register, adding a firable target proc" do
      chan = Wires::Channel.new('convenience_on_A')
      
      it_happened = false
      on :event, 'convenience_on_A' do
        it_happened = true
      end
      
      chan.fire :event
      Wires::Hub.join_children
      
      it_happened.must_equal true
    end
    
    it "can accept an actual Channel object as the channel argument" do
      chan = Wires::Channel.new('convenience_on_B')
      
      it_happened = false
      on :event, chan do
        it_happened = true
      end
      
      chan.fire :event
      Wires::Hub.join_children
      
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
      
      for chan in chans
        chan.fire :event
      end
      Wires::Hub.join_children
      
      count.must_equal chans.size
    end
    
    it "returns the &proc passed in" do
      proc = Proc.new { nil }
      assert_equal (on :event, 'convenience_on_A', &proc), proc
    end
    
  end
  
end