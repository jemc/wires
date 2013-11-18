
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
                self,        Object.new, Hash.new]}
  
  # Convenience function for creating a set of channels by names
  def channels_from names
    names.map{|x| Wires::Channel[x]}
  end
  
  # Clean out channel list between each test
  before { Wires::Channel.router.clear_channels }
  
  
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
    
    it "needs to be further tested here"
    
    it "calls the hooks registered in :@before_fire and :@after_fire" do
      flop     = false
      last_ran = :after_2
      
      b1_hook = Wires::Channel.add_hook(:@before_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject
        expect(last_ran).to eq :after_2
        last_ran             = :before_1
      end
      
      b2_hook = Wires::Channel.add_hook(:@before_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject
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
        expect(chan).to eq subject
        expect(last_ran).to eq :actual
        last_ran             = :after_1
      end
      
      a2_hook = Wires::Channel.add_hook(:@after_fire) do |evt, chan|
        expect(evt).to eq event
        expect(chan).to eq subject
        expect(last_ran).to eq :after_1
        last_ran             = :after_2
      end
      
      # Note that after_hooks are only guaranteed to happen after
      #  the call to #fire, not after the handlers are executed;
      #  therefore, they are only guaranteed to execute after the
      #  handlers when blocking is set to true
      subject.fire event, blocking:true; expect(flop).to be true
      subject.fire event, blocking:true; expect(flop).to be false
    end
  end
  
  
  describe "#fire!" do
    
    it "needs to be further tested here"
    
  end
  
end
