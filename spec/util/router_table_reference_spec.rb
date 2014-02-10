
require 'wires'

require 'spec_helper'


describe Wires::RouterTable::AbstractReference, iso:true do
  subject { Wires::RouterTable::AbstractReference.new(obj) }
  
  # Check that weak? matches actual weakness
  after { subject.ref.should be_a \
    (subject.weak? ? Ref::WeakReference : Ref::StrongReference) }
  
  context "with a GC-able (non-frozen) object" do
    let(:obj) { Object.new }
    
    its('ref.object') { should eq obj }
    
    its(:weak?) { should be }
    its(:weak?) { subject.make_weak;   should be }
    its(:weak?) { subject.make_strong; should_not be }
    its(:weak?) { subject.make_strong; 
                  subject.make_weak;   should be }
  end
  
  context "with a non-GCable (frozen) object" do
    let(:obj) { :symbol }
    
    its('ref.object') { should eq obj }
    
    its(:weak?) { should_not be }
    its(:weak?) { subject.make_weak;   should_not be }
    its(:weak?) { subject.make_strong; should_not be }
    its(:weak?) { subject.make_strong; 
                  subject.make_weak;   should_not be }
  end
end
