
require 'wires'

require 'spec_helper'


describe Wires::Channel do
  
  # A Channel object to operate on
  subject { Wires::Channel.new 'channel' }
  
  # Some common objects to operate with
  let(:event) { Wires::Event.new }
  let(:event2) { :other_event[] }
  let(:a_proc)  { Proc.new { nil } }
  let(:names) {['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                '*',         Object.new, Hash.new]}
  let(:event_patterns) { [
                :dog, :*, Wires::Event.new, 
                :dog[55], :dog[55,66], 
                :dog[arg1:32], :dog[55,arg1:32],
                [:dog,:wolf,:hound,:mutt] ] }
  
  # Convenience function for creating a set of channels by names
  def channels_from names
    names.map{|x| Wires::Channel[x]}
  end
  
  # Clean out channel list between each test
  before { Wires::Channel.router = Wires::Router::Default
           Wires::Channel.router.clear_channels }
  
  describe ".new / #initialize" do
    it "creates exactly one unique instance for each unique name" do
      past_channels = []
      for name in names
        past_channels << (c = Wires::Channel.new(name))
        expect(Wires::Channel.new(name)).to equal c
      end
      expect(past_channels.map(&:name)).to match_array names
    end
    
    it "assigns new/existing objects in a threadsafe way" do
      for n in 1..5
        threads = []
        channels = []
        for m in 0..100
          threads[m] = Thread.new {channels<<Wires::Channel.new(n)}
        end
        threads.each &:join
        expect(channels.uniq.size).to eq 1
      end
    end
    
    def loop_gc_with_timeout
      start_time = Time.now
      refs = []
      loop { # loop until one of the channel name objects is gone
        refs << Ref::WeakReference.new(Object.new)
        chan = Wires::Channel.new refs.last.object
        yield chan if block_given?
        GC.start
        break if refs.map(&:object).map(&:nil?).any?
        raise Timeout::Error if Time.now-0.5 > start_time
      }
    end
    
    it "doesn't prevent the name object from being garbage collected" do
      expect { loop_gc_with_timeout }.not_to raise_error
    end
    
    it "will prevent the name object from being garbage collected"\
       " if a handler has been registered" do
      expect { loop_gc_with_timeout { |chan|
        chan.register event, &a_proc
      }}.to raise_error Timeout::Error
    end
    
    it "won't prevent the name object from being garbage collected"\
       " if all handlers have been unregistered" do
      expect { loop_gc_with_timeout { |chan|
        chan.register event, &a_proc
        a_proc.unregister
      }}.not_to raise_error
    end
    
    it "will prevent the name object from being garbage collected"\
       " if not all handlers have been unregistered" do
      expect { loop_gc_with_timeout { |chan|
        chan.register event, &a_proc
        chan.register event, &Proc.new{}
        a_proc.unregister
      }}.to raise_error Timeout::Error
    end
    
  end
  
  
  describe "#handlers" do
    its(:handlers) { should be_an Array }
    its(:handlers) { should be_empty }
    its(:handlers) { subject.register event, &a_proc
                     should_not be_empty }
  end
  
  
  describe "#register" do
    its(:handlers) { subject.register event, &a_proc
                     should include [[event], a_proc] }
    
    its(:handlers) { subject.register event, event2, &a_proc
                     should include [[event, event2], a_proc] }
    
    around { |ex| Ref::Mock.use { ex.run } }
    
    it "returns the registered proc" do
      expect(subject.register(event, &a_proc)).to eq a_proc
    end
    
    it "attaches an #unregister method to the returned proc" do
      return_val = subject.register(event, &a_proc)
      
      expect(return_val.unregister).to eq [subject]
      expect(subject.handlers).to eq []
      
      expect(return_val.unregister).to eq []
      expect(subject.handlers).to eq []
    end
    
    it "attaches an #unregister method that works for "\
       "all Channels with that proc registered within" do
      chan1 = Wires::Channel[Object.new]
      chan2 = Wires::Channel[Object.new]
      
      return_val  = subject.register(event, &a_proc)
      return_val1 = chan1.register(event, &a_proc)
      return_val2 = chan2.register(event, &a_proc)
      
      expect(return_val1).to eq return_val
      expect(return_val2).to eq return_val
      
      expect(return_val.unregister).to match_array [subject, chan1, chan2]
      expect(return_val.unregister).to eq []
      
      expect(subject.handlers).to eq []
      expect(chan1.handlers).to eq []
      expect(chan2.handlers).to eq []
    end
    
    it "can hold a weak reference instead if requested" do
      bucket = []
      return_val = subject.register event, weak:true do
        bucket << 88
      end
      return_val.should be_a Proc
      
      subject.fire! event; bucket.count.should eq 1
      subject.fire! event; bucket.count.should eq 2
      Ref::Mock.gc
      subject.fire! event; bucket.count.should eq 2
    end
  end
  
  
  describe "#unregister" do
    its(:handlers) { "with a matching proc, unregisters the registration of it"
                     subject.register event, &a_proc
                     subject.unregister &a_proc
                     should be_empty }
    
    its(:handlers) { "with a matching proc, unregisters all registrations of it"
                     subject.register event, &a_proc
                     subject.register :other_event, &a_proc
                     subject.register :yet_another_event, &a_proc
                     subject.unregister &a_proc
                     should be_empty }
    
    its(:handlers) { "with a non-matching proc, does nothing"
                     subject.register event, &a_proc
                     subject.unregister &Proc.new{nil}
                     should_not be_empty }
    
    it "returns true/false to indicate if an unregistration occurred" do
      expect(subject.unregister(&a_proc)).to eq false
      subject.register event, &a_proc
      expect(subject.unregister(&a_proc)).to eq true
    end
  end
  
  
  describe "#receivers" do
    before { channels_from names }
    its(:receivers) { should eq Wires::Router::Default.get_receivers subject }
  end
  
  
  describe "#=~" do
    let(:channels) { channels_from names }
    it "returns true/false to indicate if 'a' is a receiver of 'b'" do
      for a in channels
        for b in channels
          (Wires::Channel.router.get_receivers(b).include? a) ?
            (expect(a).to     be =~ b) :
            (expect(a).not_to be =~ b)
        end
      end
    end
  end
  
  
  describe ".router" do
    specify { expect(Wires::Channel.router).to eq Wires::Router::Default }
  end
  
  
  describe ".router=" do
    around { Wires::Channel.router = Wires::Router::Simple; channels_from names}
    before { Wires::Channel.router = Wires::Router::Default }
    
    specify { expect(Wires::Channel.router).to eq Wires::Router::Simple }
    its(:receivers) { should eq Wires::Router::Simple.get_receivers subject }
  end
  
  
  describe "#fire" do
    
    it "fires the given event to handlers registered on"\
       " receivers of the given channel" do
      channels = channels_from(names)
      received = []
      channels.each { |c| c.register(:event) { received << c } }
      
      channels.reject{|c| c.name.is_a? Regexp}.each do |channel|
        channel.fire :event, blocking:true
        expect(received).to match_array channel.receivers
        received.clear
      end
    end
    
    it "fires the given event to handlers listening for"\
       " an event pattern matching the fired event (see Event#=~)" do
      received = []
      event_patterns.each { |e| subject.register(e) { received << e } }
      
      event_patterns.reject{|e| e.is_a? Array}.each do |e|
        subject.fire e, blocking:true
        expect(received).to match_array (event_patterns.select { |e2| 
          a = Wires::Event.list_from(e2)
          b = Wires::Event.list_from(e)
          a.map{|x| x=~b.first}.any?
        })
        received.clear
      end
    end
    
    it "calls the hooks registered in :@before_fire and :@after_fire" do
      flop     = false
      last_ran = :after_2
      
      b1_hook = Wires::Channel.add_hook(:@before_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject.name
        expect(last_ran).to eq :after_2
        last_ran             = :before_1
      end
      
      b2_hook = Wires::Channel.add_hook(:@before_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject.name
        expect(last_ran).to eq :before_1
        last_ran             = :before_2
      end
      
      subject.register event do
        expect(last_ran).to eq :before_2
        last_ran             = :actual
        flop = !flop
      end
      
      a1_hook = Wires::Channel.add_hook(:@after_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject.name
        expect(last_ran).to eq :actual
        last_ran             = :after_1
      end
      
      a2_hook = Wires::Channel.add_hook(:@after_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject.name
        expect(last_ran).to eq :after_1
        last_ran             = :after_2
      end
      
      # Note that after_hooks are only guaranteed to happen after
      #  the call to #fire, not after the handlers are executed;
      #  therefore, they are only guaranteed to execute after the
      #  handlers when blocking is set to true
      subject.fire event, blocking:true; expect(flop).to be true
      subject.fire event, blocking:true; expect(flop).to be false
      
      # Repeal all four hooks
      Wires::Channel.remove_hook(:@after_fire,  &a1_hook)
      Wires::Channel.remove_hook(:@after_fire,  &a2_hook)
      Wires::Channel.remove_hook(:@before_fire, &b1_hook)
      Wires::Channel.remove_hook(:@before_fire, &b2_hook)
    end
    
  end
  
  
  describe "#fire" do
    let(:on_method)   { Proc.new { |e,c,&blk| c.register e,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| c.fire     e,**kw } }
    
    it_behaves_like "a non-blocking fire method"
  end
  
  
  describe "#fire!" do
    let(:on_method)   { Proc.new { |e,c,&blk| c.register e,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| c.fire!    e,**kw } }
    
    it_behaves_like "a blocking fire method"
  end
  
  
  describe "#sync_on" do
    let(:freed) { [] }
    before {
      subject.register :tie_up do |e|
        sleep 0.05
        freed << self
        subject.fire :free_up[*e.args,**e.kwargs]
      end
    }
    let!(:start_time) { Time.now }
    def elapsed_time; Time.now - start_time; end
    def should_timeout(duration)
      elapsed = elapsed_time
      elapsed.should be <  duration+0.1
      elapsed.should be >= duration
    end
    def should_not_timeout(duration)
      elapsed = elapsed_time
      elapsed.should be < duration
    end
    
    it "can wait within a block until a given event is fired on the channel" do
      subject.sync_on :free_up do
        subject.fire :tie_up
        freed.should be_empty
      end
      freed.should_not be_empty
    end
    
    it "always returns nil" do
      subject.sync_on :free_up do
        subject.fire :tie_up
      end.should eq nil
    end
    
    it "is re-entrant to allow matching blocking fire within" do
      subject.sync_on :free_up do
        subject.fire! :free_up
      end
    end
    
    it "can wait with a timeout" do
      subject.sync_on :free_up, timeout:0.2 do
        subject.fire :nothing
        freed.should be_empty
      end
      freed.should be_empty
      should_timeout 0.2
    end
    
    it "can wait with extra conditions" do
      subject.sync_on :free_up, timeout:0.2 do |s|
        subject.fire :tie_up[1,2,3]
        s.condition { |e|   e.args.include? 1 }
        s.condition { |e,c| e.args.include? 2; c.should eq subject.name }
      end
      freed.should_not be_empty
      should_not_timeout 0.2
    end
    
    it "will timeout when extra conditions are not met" do
      subject.sync_on :free_up, timeout:0.2 do |s|
        subject.fire :tie_up[1,2,3]
        s.condition { |e| e.args.include? 1 }
        s.condition { |e| e.args.include? 999 } # won't be met
      end
      freed.should_not be_empty
      should_timeout 0.2
    end
    
    it "can wait with one or more blocks to execute on the matching event" do
      bucket1, bucket2 = [], []
      subject.sync_on :free_up do |s|
        subject.fire :tie_up[1,2,3]
        s.condition { |e| e.args.include? 1 }
        s.condition { |e| e.args.include? 2 }
        s.execute { |e|   bucket1 << e }
        s.execute { |e,c| bucket2 << e; c.should eq subject.name }
      end
      bucket1.should match_array [:free_up[1,2,3]]
      bucket2.should match_array [:free_up[1,2,3]]
    end
    
    it "will not run the execute blocks if the wait timed out" do
      bucket1, bucket2 = [], []
      subject.sync_on :free_up, timeout:0.2 do |s|
        subject.fire :tie_up[1,2,3]
        s.condition { |e| e.args.include? 1 }
        s.condition { |e| e.args.include? 999 } # won't be met
        s.execute { |e| bucket1 << e }
        s.execute { |e| bucket2 << e }
      end
      bucket1.should be_empty
      bucket2.should be_empty
      should_timeout 0.2
    end
    
    it "can wait at an explicit point within the block" do
      subject.sync_on :free_up do |s|
        subject.fire :tie_up
        freed.should be_empty
        s.wait.should eq :free_up[]
        freed.should_not be_empty
      end
      freed.should_not be_empty
    end
    
    it "can wait at an explicit point with a timeout" do
      subject.sync_on :free_up do |s|
        subject.fire :tie_up
        freed.should be_empty
        s.wait(0.2).should eq :free_up[]
        freed.should_not be_empty
      end
      freed.should_not be_empty
    end
    
    it "can wait at an explicit point, giving nil if timed out" do
      subject.sync_on :free_up do |s|
        subject.fire :nothing
        s.wait(0.2).should eq nil
        freed.should be_empty
      end
      freed.should be_empty
      should_timeout 0.2
    end
    
    it "can wait at an explicit point using the default timeout" do
      subject.sync_on :free_up, timeout:0.2 do |s|
        s.wait.should eq nil
      end
      should_timeout 0.2
    end
    
    it "can wait at an explicit point using some other timeout" do
      subject.sync_on :free_up, timeout:500 do |s|
        s.wait(0.2).should eq nil
      end
      should_timeout 0.2
    end
    
    it "can wait multiple explicit times" do
      subject.sync_on :free_up do |s|
        subject.fire :tie_up[1,2,3]
        freed.count.should be 0
        s.wait(0.2).should eq :free_up[1,2,3]
        subject.fire :tie_up[4,5,6]
        freed.count.should be 1
        s.wait(0.2).should eq :free_up[4,5,6]
        freed.count.should be 2
        s.wait(0.2).should eq nil
      end
    end
    
    it "will queue up matching events for additional waits" do
      subject.sync_on :free_up do |s|
        freed.count.should be 0
        3.times { subject.fire! :tie_up }
        freed.count.should be 3
        3.times { s.wait(0.2).should eq :free_up }
        s.wait(0.2).should eq nil
      end
    end
    
    it "lets exceptions raised from within an execute block pass out" do
      expect {
        subject.sync_on :free_up do |s|
          subject.fire :tie_up
          s.execute { raise RuntimeError, 'whoops' }
        end
      }.to raise_error RuntimeError, /whoops/
    end
    
    it "lets exceptions raised from within a condition block pass out" do
      expect {
        subject.sync_on :free_up do |s|
          subject.fire :tie_up
          s.condition { raise RuntimeError, 'whoops' }
        end
      }.to raise_error RuntimeError, /whoops/
    end
  end
  
end
