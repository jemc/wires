
require 'spec_helper'


describe Wires::CoreExt::Symbol do
  
  let(:block) { Proc.new { } }
  
  describe "#[]" do
    describe "without arguments" do
      subject { :some_event[] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:args)      { should eq []           }
      its(:kwargs)    { should eq({})          }
      its(:codeblock) { should_not be }
      
      its([:args])      { should_not be }
      its([:kwargs])    { should_not be }
      its([:codeblock]) { should_not be }
    end
    
    context "with arguments" do
      subject { :some_event[1, 2, 3, a:4, b:5, &block] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:args)      { should eq [1, 2, 3] }
      its(:kwargs)    { should eq a:4, b:5  }
      its(:codeblock) { should eq block }
      
      its([:args])      { should_not be }
      its([:kwargs])    { should_not be }
      its([:codeblock]) { should_not be }
      
      its([:a])    { should eq 4 }
      its([:b])    { should eq 5 }
      
      its(:a)      { should eq 4 }
      its(:b)      { should eq 5 }
    end
    
    context "with :type keyword argument" do
      subject { :some_event[1, 2, 3, a:4, b:5, type: :test, &block] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:args)      { should eq [1, 2, 3] }
      its(:kwargs)    { should eq a:4, b:5  }
      its(:codeblock) { should eq block }
      
      its([:args])      { should_not be }
      its([:kwargs])    { should_not be }
      its([:codeblock]) { should_not be }
      
      its([:a])    { should eq 4 }
      its([:b])    { should eq 5 }
      
      its(:a)      { should eq 4 }
      its(:b)      { should eq 5 }
    end
      
    context "with :args keyword argument" do
      subject { :some_event[1,2,3, args:[5,6,7]] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:args)        { should eq [1, 2, 3] }
      its([:args])      { should eq [5, 6, 7] }
    end
      
    context "with :kwargs keyword argument" do
      subject { :some_event[a:1,b:2, kwargs:{a:4,b:5}] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:kwargs)      { should eq a:1, b:2, kwargs:{a:4,b:5} }
      its([:kwargs])    { should eq({a:4,b:5}) }
    end
    
    context "with :codeblock keyword argument" do
      subject { :some_event[codeblock: :anything, &block] }
      
      its(:class)     { should eq Wires::Event }
      its(:type)      { should eq :some_event  }
      
      its(:codeblock)   { should eq block }
      its([:codeblock]) { should eq :anything }
    end
  end
  
  describe "#to_wires_event" do
    subject { :some_event }
    its(:to_wires_event) { should eq :some_event[] }
  end
  
end
