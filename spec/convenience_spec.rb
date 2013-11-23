
require 'wires'

require 'spec_helper'


describe Wires::Convenience do
  subject { Object.new.extend Wires::Convenience }
  
  describe "#fire and #on" do
    let(:on_method)   { Proc.new { |e,c,&blk| subject.on   e,c,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| subject.fire e,c,**kw } }
    
    it_behaves_like "a variable-channel fire method"
    it_behaves_like "a non-blocking fire method"
    
    # it "can do time related stuff as well"
  end
  
  describe "#fire! and #on" do
    let(:on_method)   { Proc.new { |e,c,&blk| subject.on    e,c,&blk } }
    let(:fire_method) { Proc.new { |e,c,**kw| subject.fire! e,c,**kw } }
    
    it_behaves_like "a variable-channel fire method"
    it_behaves_like "a blocking fire method"
  end 
end
