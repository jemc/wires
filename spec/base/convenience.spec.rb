
require 'wires'

require 'spec_helper'


describe Wires::Convenience do
  subject { Object.new.extend Wires::Convenience }
  
  describe "#fire and #on" do
    let(:on_method)   { Proc.new { |e,c,&blk| subject.on   e,c,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| subject.fire e,c,**kw } }
    
    it_behaves_like "a variable-channel fire method"
    it_behaves_like "a non-blocking fire method"
    
    it "fires to self by default" do
      extend Wires::Convenience
      received = false
      on(:sym, self) { |e,c| received = true }
      fire :sym
      sleep 0.15
      received.should eq true
    end
    
    it "listens on self by default" do
      extend Wires::Convenience
      received = false
      on(:sym) { |e,c| received = true }
      fire :sym, self
      sleep 0.15
      received.should eq true
    end
    # it "can do time related stuff as well"
  end
  
  describe "#fire! and #on" do
    let(:on_method)   { Proc.new { |e,c,&blk| subject.on    e,c,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| subject.fire! e,c,**kw } }
    
    it_behaves_like "a variable-channel fire method"
    it_behaves_like "a blocking fire method"
    
    it "fires to self by default" do
      extend Wires::Convenience
      received = false
      on(:sym, self) { |e,c| received = true }
      fire! :sym
      received.should eq true
    end
    
    it "listens on self by default" do
      extend Wires::Convenience
      received = false
      on(:sym) { |e,c| received = true }
      fire! :sym, self
      received.should eq true
    end
  end 
end
