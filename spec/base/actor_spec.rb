
require 'wires'
require 'wires/base/actor'

require 'spec_helper'


describe Wires::Actor, iso:true do
  let(:klass_def) { proc{} }
  let(:klass) {
    kls = Class.new
    kls.include Wires::Actor
    kls.class_eval &klass_def
    kls
  }
  let(:inst) { klass.new }
  
  let(:event_type_a)   { :type_a }
  let(:event_args_a)   { [1,2,3] }
  let(:event_kwargs_a) { {foo:88,bar:99} }
  let(:event_blk_a)    { Proc.new { } }
  let(:event_a) { event_type_a[*event_args_a, **event_kwargs_a, &event_blk_a] }
  
  let(:event_type_b)   { :type_b }
  let(:event_args_b)   { [5,6,7] }
  let(:event_kwargs_b) { {foo:22,bar:33} }
  let(:event_blk_b)    { Proc.new { } }
  let(:event_b) { event_type_b[*event_args_b, **event_kwargs_b, &event_blk_b] }
  
  let(:event_type)   { event_type_a }
  let(:event_args)   { event_args_a }
  let(:event_kwargs) { event_kwargs_a }
  let(:event_blk)    { event_blk_a }
  let(:event)        { event_a }
  
  describe "when included in a class" do
    subject { inst }
    let(:klass_def) { proc { handler :type_a; handler :type_b } }
    
    it { should be_a Wires::Actor }
    
    it "forwards incoming events to method calls" do
      subject.listen_on 'channel'
      
      expect(subject).to receive(event_type_a)
        .with(*event_args_a, **event_kwargs_a, &event_blk_a)
      Wires::Channel['channel'].fire! event_a
      
      expect(subject).to receive(event_type_b)
        .with(*event_args_b, **event_kwargs_b, &event_blk_b)
      Wires::Channel['channel'].fire! event_b
    end
  end
end
