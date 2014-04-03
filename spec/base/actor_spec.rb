
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
  
  let(:event_type_c)   { :type_c }
  let(:event_args_c)   { [8,9,0] }
  let(:event_kwargs_c) { {foo:44,bar:55} }
  let(:event_blk_c)    { Proc.new { } }
  let(:event_c) { event_type_c[*event_args_c, **event_kwargs_c, &event_blk_c] }
  
  let(:event_type)   { event_type_a }
  let(:event_args)   { event_args_a }
  let(:event_kwargs) { event_kwargs_a }
  let(:event_blk)    { event_blk_a }
  let(:event)        { event_a }
  
  describe "when included in a class" do
    subject { inst }
    let(:klass_def) { proc {
      def type_a(*args) end
      def type_b(*args) end
      handler :type_a
      handler :type_b
    } }
    
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
    
    it "overwrites the old listen_on call when listen_on is called again" do
      subject.listen_on 'channel_old'
      subject.listen_on 'channel' # Overwrite 'channel_old'
      subject.listen_on 'channel' # Overwrite 'channel' - essentially no effect
      
      expect(subject).to receive(event_type_a)
        .with(*event_args_a, **event_kwargs_a, &event_blk_a)
      Wires::Channel['channel'].fire! event_a
      
      expect(subject).to receive(event_type_b)
        .with(*event_args_b, **event_kwargs_b, &event_blk_b)
      Wires::Channel['channel'].fire! event_b
      
      Wires::Channel['channel_old'].fire! event_a # Expect no forwarding
      Wires::Channel['channel_old'].fire! event_b # Expect no forwarding
    end
    
    describe "with event type specified" do
      let(:klass_def) { proc {
        def foo(*args) end
        def type_b(*args) end
        handler :foo, :event=>:type_a
        handler :type_b
      } }
      
      it "will forward events of that type to the given method name" do
        subject.listen_on 'channel'
        
        expect(subject).to receive(:foo)
          .with(*event_args_a, **event_kwargs_a, &event_blk_a)
        Wires::Channel['channel'].fire! event_a
        
        expect(subject).to receive(event_type_b)
          .with(*event_args_b, **event_kwargs_b, &event_blk_b)
        Wires::Channel['channel'].fire! event_b
      end
    end
    
    describe "with :expand=>false" do
      let(:klass_def) { proc {
        def type_a(*args) end
        def type_b(*args) end
        handler :type_a, :expand=>false
        handler :type_b
      } }
      
      it "will send event, channel as arguments instead of the event args" do
        subject.listen_on 'channel'
        
        expect(subject).to receive(event_type_a)
          .with(event_a, 'channel')
        Wires::Channel['channel'].fire! event_a
        
        expect(subject).to receive(event_type_b)
          .with(*event_args_b, **event_kwargs_b, &event_blk_b)
        Wires::Channel['channel'].fire! event_b
      end
    end
    
    describe "with :channel specified" do
      let(:klass_def) { proc {
        def type_a(*args) end
        def type_b(*args) end
        def type_c(*args) end
        handler :type_a, :channel=>:alpha
        handler :type_b, :channel=>:beta
        handler :type_c
      } }
      
      it "will filter/route events based on channel codes in listen_on" do
        subject.listen_on 'channel', 'other', alpha:'AAA', beta:'BBB'
        
        expect(subject).to receive(event_type_a)
          .with(*event_args_a, **event_kwargs_a, &event_blk_a)
        Wires::Channel['AAA'].fire! event_a
        
        expect(subject).to receive(event_type_b)
          .with(*event_args_b, **event_kwargs_b, &event_blk_b)
        Wires::Channel['BBB'].fire! event_b
        
        expect(subject).to receive(event_type_c)
          .with(*event_args_c, **event_kwargs_c, &event_blk_c)
        Wires::Channel['channel'].fire! event_c
        
        expect(subject).to receive(event_type_c)
          .with(*event_args_c, **event_kwargs_c, &event_blk_c)
        Wires::Channel['other'].fire! event_c
        
        Wires::Channel['AAA'].fire! event_b # Expect no forwarding
        Wires::Channel['AAA'].fire! event_c # Expect no forwarding
        Wires::Channel['BBB'].fire! event_a # Expect no forwarding
        Wires::Channel['BBB'].fire! event_c # Expect no forwarding
        Wires::Channel['channel'].fire! event_a # Expect no forwarding
        Wires::Channel['channel'].fire! event_b # Expect no forwarding
      end
    end
    
    describe "when handler isn't called in the class definition" do
      let(:klass_def) { proc {
        def type_a(*args) raise "Unexpected call to #{__method__}" end
        def type_b(*args) raise "Unexpected call to #{__method__}" end
      } }
      
      it "can set up an instance-local handler in the object" do
        subject.listen_on 'channel'
        
        Wires::Channel['channel'].fire! event_a # Expect no forwarding
        Wires::Channel['channel'].fire! event_b # Expect no forwarding
        
        subject.handler :type_a
        subject.handler :type_b
        
        expect(subject).to receive(event_type_a)
          .with(*event_args_a, **event_kwargs_a, &event_blk_a)
        Wires::Channel['channel'].fire! event_a
        
        expect(subject).to receive(event_type_b)
          .with(*event_args_b, **event_kwargs_b, &event_blk_b)
        Wires::Channel['channel'].fire! event_b
      end
    end
  end
end
