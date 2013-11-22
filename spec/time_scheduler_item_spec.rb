
require 'timecop'


shared_context "seconds have passed", :seconds=>:have_passed do |ex|
  let(:time_difference_in_seconds) { 
    ex.metadata[:example_group][:description_args].last }
  before { time; subject; Timecop.travel Time.now+time_difference_in_seconds }
  after  { Timecop.return }
end


shared_examples "an exhausted item" do
  its(:active?)   { should be_false }
  its(:ready?)    { should be_false }
  its(:count)     { should eq 0     }
  
  it "refuses to be conditionally fired" do
    expect(subject.fire_if_ready).to be_false
    
    expect(subject.active?)  .to be_false
    expect(subject.ready?)   .to be_false
    expect(subject.count)    .to eq 0
  end
  
  it "can still be unconditionally fired" do
    expect(subject.fire).to be_true
    
    expect(subject.active?)  .to be_false
    expect(subject.ready?)   .to be_false
    expect(subject.count)    .to eq 0
  end
end


shared_examples "a ready item with a count of 1" do
  its(:active?)   { should be_true  }
  its(:ready?)    { should be_true  }
  its(:count)     { should eq 1     }
  
  context "when conditionally fired" do
    before { expect(subject.fire_if_ready).to be_true }
    it_behaves_like "an exhausted item"
  end
  
  context "when unconditionally fired" do
    before { expect(subject.fire).to be_true }
    it_behaves_like "an exhausted item"
  end
end


shared_examples "an unready item with a count of 1" do
  its(:active?)   { should be_true  }
  its(:ready?)    { should be_false }
  its(:count)     { should eq 1     }
  
  it "refuses to be conditionally fired" do
    expect(subject.fire_if_ready).to be_false
    
    expect(subject.active?)  .to be_true
    expect(subject.ready?)   .to be_false
    expect(subject.count)    .to eq 1
  end
  
  context "when unconditionally fired" do
    before { expect(subject.fire).to be_true }
    it_behaves_like "an exhausted item"
  end
end


shared_examples "a disabled item with a count of 1" do
  its(:active?)   { should be_false }
  its(:ready?)    { should be_false }
  its(:count)     { should eq 1     }
  
  it "refuses to be conditionally fired" do
    expect(subject.fire_if_ready).to be_false
    
    expect(subject.active?)  .to be_false
    expect(subject.ready?)   .to be_false
    expect(subject.count)    .to eq 1
  end
  
  context "when unconditionally fired" do
    before { expect(subject.fire).to be_true }
    it_behaves_like "an exhausted item"
  end
end


shared_examples "an item that internalized its args correctly" do
  its(:time)        { should eq time }
  its(:events)      { should eq Wires::Event.new_from(events) }
  its(:channel)     { should eq Wires::Channel[chan_name] }
  its(:interval)    { should eq (kwargs[:interval] or 0) }
  its(:jitter)      { should eq (kwargs[:jitter]   or 0) }
  its(:fire_kwargs) { should eq fire_kwargs }
end


describe Wires::TimeSchedulerItem do
  after { Wires::Hub.join_children; Wires::TimeScheduler.clear }
  
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
    it_behaves_like "a ready item with a count of 1"
  end
  
  describe "an item scheduled for the future" do
    let(:time)   { Time.now + 5 }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "an unready item with a count of 1"
    
    context "after", 5, :seconds=>:have_passed do
      it_behaves_like "a ready item with a count of 1"
    end
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
    it_behaves_like "a disabled item with a count of 1"
  end
  
  describe "scheduled for the future, with active:false" do
    let(:time)   { Time.now + 5 }
    let(:kwargs) { {active:false} }
    
    it_behaves_like "an item that internalized its args correctly"
    it_behaves_like "a disabled item with a count of 1"
  end
  
  # it "can hold a repeating event" do
  #   time = Time.now
  #   count = 25
  #   interval = 1.seconds
  #   item = Wires::TimeSchedulerItem.new(time, :event, 
  #                                       count:count, interval:interval)
  #   item.active? .must_equal true
  #   item.count   .must_equal count
  #   item.interval.must_equal interval
  # end
  
end
