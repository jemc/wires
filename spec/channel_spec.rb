
require 'wires'

# require 'pry-rescue/rspec'


describe Wires::Channel do
  
  # A Channel object to operate on
  subject { Wires::Channel.new 'channel' }
  
  # Some common objects to operate with
  let(:event) { Wires::Event.new }
  let(:proc)  { Proc.new { nil } }
  let(:names) {['channel',   'Channel',  'CHANNEL',
                :channel,    :Channel,   :CHANNEL,
                /channel/,   /Channel/,  /CHANNEL/,
               ['channel'], [:channel], [/channel/],
                '*',         Object.new, Hash.new]}
  let(:event_patterns) { [
                :dog, :*, Wires::Event.new, 
                {dog:[55]}, {dog:[55,66]}, 
                {dog:[arg1:32]}, {dog:[55,arg1:32]},
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
        expect(Wires::Channel.new(name)).to eq c
      end
      expect(past_channels.map{|c| c.name}).to match_array names
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
  end
  
  
  describe "#handlers" do
    its(:handlers) { should be_an Array }
    its(:handlers) { should be_empty }
    its(:handlers) { subject.register event, &proc
                     should_not be_empty }
  end
  
  
  describe "#register" do
    its(:handlers) { subject.register event, &proc
                     should include [[event], proc] }
    
    its(:handlers) { subject.register event, event, &proc
                     should include [[event, event], proc] }
    
    it "returns the registered proc" do
      expect(subject.register(event, &proc)).to eq proc
    end
  end
  
  
  describe "#unregister" do
    its(:handlers) { "with a matching proc, unregisters the registration of it"
                     subject.register event, &proc
                     subject.unregister proc
                     should be_empty }
    
    its(:handlers) { "with a matching proc, unregisters all registrations of it"
                     subject.register event, &proc
                     subject.register :other_event, &proc
                     subject.register :yet_another_event, &proc
                     subject.unregister proc
                     should be_empty }
    
    its(:handlers) { "with a non-matching proc, does nothing"
                     subject.register event, &proc
                     subject.unregister Proc.new{nil}
                     should_not be_empty }
    
    it "returns true/false to indicate if an unregistration occurred" do
      expect(subject.unregister(proc)).to eq false
      subject.register event, &proc
      expect(subject.unregister(proc)).to eq true
      expect(subject.unregister(proc)).to eq false
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
          a = Wires::Event.new_from(e2)
          b = Wires::Event.new_from(e)
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
  
  
  # Convenience method to test concurrency properties of a firing block
  def fire_test blocking:false, parallel:!blocking
    count = 0
    running_count = 0
    10.times do
      subject.register(:event) do
        if parallel
          expect(count).to eq 0
          sleep 0.1
        else
          expect(count).to eq running_count
          running_count += 1
          sleep 0.01
        end
        count += 1
      end
    end
    
    yield # to block that fires
    
    if not blocking
      expect(count).to eq 0
      sleep 0.15
    end
    expect(count).to eq 10
  end
  
  
  describe "#fire" do
    it "fires non-blocking and in parallel by default" do
      fire_test              blocking:false, parallel:true do
        subject.fire :event
      end
    end
    
    it "can fire non-blocking and in sequence with parallel:false" do
      fire_test              blocking:false, parallel:false do
        subject.fire :event, parallel:false
      end
    end
    
    it "can fire blocking and in sequence with blocking:true" do
      fire_test              blocking:true, parallel:false do
        subject.fire :event, blocking:true
      end
    end
    
    it "can fire blocking and in parallel with blocking:true, parallel:true" do
      fire_test              blocking:true, parallel:true do
        subject.fire :event, blocking:true, parallel:true
      end
    end
  end
  
  
  describe "#fire!" do
    it "fires blocking and in sequence by default" do
      fire_test               blocking:true, parallel:false do
        subject.fire! :event
      end
    end
    
    it "can fire blocking and in parallel with parallel:true" do
      fire_test               blocking:true, parallel:true do
        subject.fire! :event, parallel:true
      end
    end
    
    it "can fire non-blocking and in parallel with blocking:false" do
      fire_test               blocking:false, parallel:true do
        subject.fire! :event, blocking:false
      end
    end
    
    it "can fire non-blocking and in sequence with blocking:false, parallel:false" do
      fire_test               blocking:false, parallel:false do
        subject.fire! :event, blocking:false, parallel:false
      end
    end
  end
  
end
