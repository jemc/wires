
require 'wires'
require 'wires/base/actor'

require 'spec_helper'


describe Wires::Actor do
  let(:klass_def) { proc{} }
  let(:klass) {
    kls = Class.new
    kls.include Wires::Actor
    kls.class_eval &klass_def
    kls
  }
  let(:inst) { klass.new }
  
  describe "when included in a class" do
    subject { inst }
    let(:klass_def) { proc { handler :type } }
    
    let(:event_type)   { :type }
    let(:event_args)   { [1,2,3] }
    let(:event_kwargs) { {foo:88,bar:99} }
    let(:event_block)  { Proc.new{nil} }
    let(:event) { event_type[*event_args, **event_kwargs, &event_block] }
    
    it { should be_a Wires::Actor }
    
    it "forwards incoming events to method calls" do
      expect(subject).to receive(event_type)
        .with(*event_args, **event_kwargs, &event_block)
      subject.listen_on subject
      Wires::Channel[subject].fire! event
    end
    
  end
end
