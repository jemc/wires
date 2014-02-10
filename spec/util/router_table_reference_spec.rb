
require 'wires'

require 'spec_helper'


shared_examples_for "a router table reference" do
  # Check that weak? matches actual weakness
  after { subject.ref.should be_a \
    (subject.weak? ? Ref::WeakReference : Ref::StrongReference) }
  
  context "with a GC-able (non-frozen) object" do
    let(:obj) { Object.new }
    
    its(:object)      { should eq obj }
    its('ref.object') { should eq obj }
    
    its(:weak?) { should be }
    its(:weak?) { subject.make_weak;   should be }
    its(:weak?) { subject.make_strong; should_not be }
    its(:weak?) { subject.make_strong; 
                  subject.make_weak;   should be }
  end
  
  context "with a non-GCable (frozen) object" do
    let(:obj) { :symbol }
    
    its(:object)      { should eq obj }
    its('ref.object') { should eq obj }
    
    its(:weak?) { should_not be }
    its(:weak?) { subject.make_weak;   should_not be }
    its(:weak?) { subject.make_strong; should_not be }
    its(:weak?) { subject.make_strong; 
                  subject.make_weak;   should_not be }
  end
end

describe Wires::RouterTable::AbstractReference, iso:true do
  subject { Wires::RouterTable::AbstractReference.new(obj) }
  it_behaves_like "a router table reference"
end

describe Wires::RouterTable::KeyReference, iso:true do
  subject { Wires::RouterTable::KeyReference.new(obj) }
  it_behaves_like "a router table reference"
  
  let(:obj) { Object.new }
  
  its(:hash) { should eq obj.hash }
  specify { subject.should eql obj }
  
  it "is 'transparent' to a hosting Hash" do
    h = {}
    h[obj.hash] = 88
    h[subject.hash].should eq 88
  end
end
