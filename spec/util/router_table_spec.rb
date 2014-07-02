
require 'spec_helper'


describe Wires::Util::RouterTable do
  
  describe Wires::Util::RouterTable::Reference do
    subject { Wires::Util::RouterTable::Reference.new(obj) }
    
    after do # Check that weak? matches actual weakness
      expect(subject.ref).to be_a \
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
  
  
  describe Wires::Util::RouterTable do
    
    after do # Check consistency of tables
      GC.start
      expect(subject.each.to_a.map(&:first)).to eq subject.keys
      expect(subject.each.to_a.map(&:last)).to eq subject.values
    end
    
    it "provides Hash-like key-indexed access" do
      subject[:foo]  = 88
      expect(subject[:foo] ).to eq 88
      expect(subject['bar']).to eq nil
      subject['bar'] = 99
      expect(subject[:foo] ).to eq 88
      expect(subject['bar']).to eq 99
      subject.delete :foo
      expect(subject[:foo] ).to eq nil
      expect(subject['bar']).to eq 99
      subject.delete 'bar'
      expect(subject[:foo] ).to eq nil
      expect(subject['bar']).to eq nil
    end
    
    it "provides Hash-like #clear" do
      subject[:foo]  = 88
      subject['bar'] = 99
      subject.clear
      expect(subject[:foo] ).to eq nil
      expect(subject['bar']).to eq nil
    end
    
    it "provides the Hash-like #keys and #values arrays" do
      subject[:foo]  = 88
      subject['bar'] = 99
      expect(subject.keys).to match_array [:foo,'bar']
      expect(subject.values).to match_array [88,99]
    end
    
    it "provides the Hash-like #each Enumerator (aliased #each_pair)" do
      subject[:foo]  = 88
      subject['bar'] = 99
      expect(subject.each.to_a).to match_array [[:foo,88],['bar',99]]
      expect(subject.each_pair.to_a).to eq subject.each.to_a
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
      expect(kref).to be_a Wires::Util::RouterTable::Reference
      expect(vref).to be_a Wires::Util::RouterTable::Reference
      expect(kref).to receive :make_weak
      expect(vref).to receive :make_weak
      
      subject.make_weak('baz')
    end
    
    it "can make_strong an entry by key" do
      subject['baz'] = Object.new
      
      kref = subject.instance_variable_get(:@keys).values.last
      vref = subject.instance_variable_get(:@values).values.last
      expect(kref).to be_a Wires::Util::RouterTable::Reference
      expect(vref).to be_a Wires::Util::RouterTable::Reference
      expect(kref).to receive :make_strong
      expect(vref).to receive :make_strong
      
      subject.make_strong('baz')
    end
    
    it "ignores when make_weak or make_strong is called on missing keys" do
      subject.make_weak(:foo)
      subject.make_strong('bar')
    end
  end
  
end
