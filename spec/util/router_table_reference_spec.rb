
require 'wires'

require 'spec_helper'


describe Wires::RouterTable::AbstractReference, iso:true do
  subject { Wires::RouterTable::AbstractReference.new(obj) }
  
  context "with a GC-able (non-frozen) object" do
    let(:obj) { Object.new }
    
    its('ref.object') { should eq obj }
    its(:ref) { should be_a Ref::WeakReference }
    its(:weak?) { should be }
  end
  
  context "with a non-GCable (frozen) object" do
    let(:obj) { :symbol }
    
    its('ref.object') { should eq obj }
    its(:ref) { should be_a Ref::StrongReference }
    its(:weak?) { should_not be }
  end
end
