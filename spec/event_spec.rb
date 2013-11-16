
require 'wires'

require 'pry-rescue/rspec'


RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


describe Wires::Event do
  
  context "without arguments" do
    its(:args)      { should eq []  }
    its(:kwargs)    { should eq({}) }
    its(:codeblock) { should_not be }
    
    its([:args])    { should eq []  }
  end
  
  context "with arguments" do
    subject{ Wires::Event.new 1, 2, 3, a:4, b:5, &:proc }
    
    its(:args)      { should eq [1, 2, 3] }
    its(:kwargs)    { should eq a:4, b:5  }
    its(:codeblock) { should eq :proc.to_proc }
    
    its([:args]) { should eq [1, 2, 3] }
    its([:a])    { should eq 4 }
    its([:b])    { should eq 5 }
    
    its(:a)      { should eq 4 }
    its(:b)      { should eq 5 }
  end
  
  context ".new_from" do
    let(:m) { Wires::Event.method(:new_from) }
    let(:event_a) { Wires::Event.new }
    let(:event_b) { Wires::Event.new }
    
    context "when given an existing Event instance or two" do
      # let(:evt_a) { Wires::Event.new }
      # let(:evt_b) { Wires::Event.new }
      
      # # subject { Wires::Event.method(:new_from) }
      
      # specify { expect(subject.call evt_a)      .to eq [evt_a] }
      # specify { expect(subject.call evt_a,evt_b).to eq [evt_a,evt_b] }
      
      its(:new_from, Wires::Event.new) { should be }
      
    end
  end
  
end


  
  describe Wires::Event.method(:new_from) do
    
  end