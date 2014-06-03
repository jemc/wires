
require 'wires'

require 'spec_helper'
require 'timecop'


shared_context "after sufficient time has passed", 
               :sufficient_time=>:has_passed do
  before { subject; Timecop.freeze subject.time }
end


shared_examples "an exhausted item" do
  its(:active?)   { should eq false }
  its(:ready?)    { should eq false }
  its(:count)     { should eq 0     }
  
  it "refuses to be conditionally fired" do
    expect(subject.fire_if_ready).to eq nil
    
    expect(subject.active?)  .to eq false
    expect(subject.ready?)   .to eq false
    expect(subject.count)    .to eq 0
  end
  
  it "can still be unconditionally fired" do
    expect(subject.fire).to eq true
    
    expect(subject.active?)  .to eq false
    expect(subject.ready?)   .to eq false
    expect(subject.count)    .to eq 0
  end
end


shared_examples "a disabled item with count" do |the_count|
  if !the_count or the_count<=0 
    it_behaves_like "an exhausted item"
  else
    its(:active?)   { should eq false }
    its(:ready?)    { should eq false }
    its(:count)     { should eq the_count }
    
    it "refuses to be conditionally fired" do
      expect(subject.fire_if_ready).to eq nil
      
      expect(subject.active?)  .to eq false
      expect(subject.ready?)   .to eq false
      expect(subject.count)    .to eq the_count
    end
    
    context "when unconditionally fired" do
      before { expect(subject.fire).to eq true }
      it_behaves_like "a disabled item with count", the_count-1
    end
  end
end


shared_examples "an item of unknown readiness with count" do |the_count|
  context "after", :sufficient_time=>:has_passed do
    it_behaves_like "a ready item with count", the_count
  end
end


shared_examples "a ready item with count" do |the_count|
  if !the_count or the_count<=0 
    it_behaves_like "an exhausted item"
  else
    its(:active?)   { should eq true }
    its(:ready?)    { should eq true }
    its(:count)     { should eq the_count }
    
    context "when conditionally fired" do
      before { expect(subject.fire_if_ready).to eq true }
      it_behaves_like "an item of unknown readiness with count", the_count-1
    end
    
    context "when unconditionally fired" do
      before { expect(subject.fire).to eq true }
      it_behaves_like "an item of unknown readiness with count", the_count-1
    end
  end
end


shared_examples "an unready item with count" do |the_count|
  if !the_count or the_count<=0 
    it_behaves_like "an exhausted item"
  else
    its(:active?)   { should eq true }
    its(:ready?)    { should eq false }
    its(:count)     { should eq the_count }
    
    it "refuses to be conditionally fired" do
      expect(subject.fire_if_ready).to eq nil
      
      expect(subject.active?)  .to eq true
      expect(subject.ready?)   .to eq false
      expect(subject.count)    .to eq the_count
    end
    
    context "when unconditionally fired" do
      before { expect(subject.fire).to eq true }
      it_behaves_like "an unready item with count", the_count-1
    end
    
    context "after", :sufficient_time=>:has_passed do
      it_behaves_like "a ready item with count", the_count
    end
  end
end


shared_examples "a repeating item with non-zero interval" do
  specify "firability over time" do
    Timecop.freeze subject.time
    
    the_count = subject.count
    
    the_count.times do |i|
      expect(subject.time).to eq Time.now
      expect(subject.fire_if_ready).to be
      expect(subject.fire_if_ready).not_to be
      
      break if i == the_count-1
      
      expected_time = Time.now+subject.interval
      if subject.jitter == 0
        expect(subject.time).to eq expected_time
      else
        expect(subject.time).not_to eq expected_time
        expect((expected_time-subject.time).abs).to be <= subject.jitter
      end
      Timecop.freeze subject.time
    end
    expect(subject.fire_if_ready).not_to be
  end
end


shared_examples "an item that internalized its args correctly" do
  its(:time) do
    if time < Time.now and kwargs[:ignore_past]
      should eq time+((kwargs[:count]||1)-subject.count)*subject.interval
    else
      should eq time
    end
  end
  its(:events)      { should eq Wires::Event.list_from(events) }
  its(:channel)     { should eq Wires::Channel[chan_name] }
  its(:interval)    { should eq (kwargs[:interval] or 0) }
  its(:jitter)      { should eq (kwargs[:jitter]   or 0) }
  its(:fire_kwargs) { should eq fire_kwargs }
end


describe Wires::TimeSchedulerItem do
  around { |example| Timecop.freeze { subject; example.run } }
  after { Wires::Launcher.join_children; Wires::TimeScheduler.clear }
  
  let(:events)      { Wires::Event.new }
  let(:chan_name)   { Object.new.tap { |x| x.extend Wires::Convenience } }
  let(:time)        { Time.now }
  let(:kwargs)      { {} }
  let(:fire_kwargs) { {} }
  
  subject { Wires::TimeSchedulerItem.new time, events, chan_name, 
                                       **(fire_kwargs.merge kwargs) }
  
  describe "an item scheduled for the past" do
    let(:time)   { Time.now - 5 }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a ready item with count", 1
  end
  
  describe "an item scheduled for the future" do
    let(:time)   { Time.now + 5 }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "an unready item with count", 1
  end
  
  describe "an item scheduled for the past with ignore_past:true" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {ignore_past:true} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "an exhausted item"
  end
  
  describe "scheduled for the past, with active:false" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {active:false} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a disabled item with count", 1
  end
  
  describe "scheduled for the future, with active:false" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {active:false} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a disabled item with count", 1
  end
  
  describe "scheduled for the past, with count:3" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:3} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a ready item with count", 3
  end
  
  describe "scheduled for the future, with count:3" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:3} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "an unready item with count", 3
  end
  
  describe "scheduled for the past, with count:3, active:false" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:3, active:false} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a disabled item with count", 3
  end
  
  describe "scheduled for the future, with count:3, active:false" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:3, active:false} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a disabled item with count", 3
  end
  
  describe "scheduled for the past, with count:3, interval:2" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:3, interval:2} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the future, with count:3, interval:2" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:3, interval:2} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the past, with count:3, interval:2, ignore_past:true" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:3, interval:2, ignore_past:true} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the future, with count:3, interval:2, ignore_past:true" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:3, interval:2, ignore_past:true} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the past, with count:33, interval:4, jitter:3" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:33, interval:4, jitter:3} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the future, with count:33, interval:4, jitter:3" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:33, interval:4, jitter:3} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the past, with count:33, interval:4, jitter:3, ignore_past:true" do
    let(:time)   { Time.now - 5 }
    let(:kwargs) { {count:33, interval:4, jitter:3, ignore_past:true} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
  
  describe "scheduled for the future, with count:33, interval:4, jitter:3, ignore_past:true" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {count:33, interval:4, jitter:3, ignore_past:true} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a repeating item with non-zero interval"
  end
end
