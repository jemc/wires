
require 'wires'

require 'spec_helper'


describe Wires::RouterTable do
  
  describe Wires::RouterTable::Reference do
    subject { Wires::RouterTable::Reference.new(obj) }
    
    after do # Check that weak? matches actual weakness
      subject.ref.should be_a \
        (subject.weak? ? Ref::WeakReference : Ref::StrongReference)
    end
    
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
  
  
  describe Wires::RouterTable do
    
    after do # Check consistency of tables
      GC.start
      subject.each.to_a.map(&:first).should eq subject.keys
      subject.each.to_a.map(&:last).should eq subject.values
    end
    
    it "provides Hash-like key-indexed access" do
      subject[:foo]  = 88
      subject[:foo] .should eq 88
      subject['bar'].should eq nil
      subject['bar'] = 99
      subject[:foo] .should eq 88
      subject['bar'].should eq 99
      subject.delete :foo
      subject[:foo] .should eq nil
      subject['bar'].should eq 99
      subject.delete 'bar'
      subject[:foo] .should eq nil
      subject['bar'].should eq nil
    end
    
    it "provides Hash-like #clear" do
      subject[:foo]  = 88
      subject['bar'] = 99
      subject.clear
      subject[:foo] .should eq nil
      subject['bar'].should eq nil
    end
    
    it "provides the Hash-like #keys and #values arrays" do
      subject[:foo]  = 88
      subject['bar'] = 99
      subject.keys.should match_array [:foo,'bar']
      subject.values.should match_array [88,99]
    end
    
    it "provides the Hash-like #each Enumerator (aliased #each_pair)" do
      subject[:foo]  = 88
      subject['bar'] = 99
      subject.each.to_a.should match_array [[:foo,88],['bar',99]]
      subject.each_pair.to_a.should eq subject.each.to_a
    end
    
    it "clears out garbage-collected keys" do
      # Create entries until at least one is garbage collected
      # If this feature fails the spec, it loops indefinitely.
      i = 0
      until subject.each.to_a.count < i
        i += 1
        subject[Object.new] = :foo
      end
    end
    
    it "can make_weak an entry by key" do
      subject['baz'] = Object.new
      
      kref = subject.instance_variable_get(:@keys).values.last
      vref = subject.instance_variable_get(:@values).values.last
      kref.should be_a Wires::RouterTable::Reference
      vref.should be_a Wires::RouterTable::Reference
      kref.should receive :make_weak
      vref.should receive :make_weak
      
      subject.make_weak('baz')
    end
    
    it "can make_strong an entry by key" do
      subject['baz'] = Object.new
      
      kref = subject.instance_variable_get(:@keys).values.last
      vref = subject.instance_variable_get(:@values).values.last
      kref.should be_a Wires::RouterTable::Reference
      vref.should be_a Wires::RouterTable::Reference
      kref.should receive :make_strong
      vref.should receive :make_strong
      
      subject.make_strong('baz')
    end
    
    it "ignores when make_weak or make_strong is called on missing keys" do
      subject.make_weak(:foo)
      subject.make_strong('bar')
    end
  end
  
end
