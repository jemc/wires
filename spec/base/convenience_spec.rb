
require 'wires'

require 'spec_helper'


describe Wires::Convenience do
  subject { Object.new.extend Wires::Convenience }
  
  let(:event) { Wires::Event.new }
  let(:channel_name) { 'test' }
  let(:channel) { Wires::Channel[channel_name] }
  let(:a_proc) { Proc.new { nil } }
  
  describe "#on" do
    it "forwards to Channel[self].register by default" do
      expect(Wires::Channel[subject]).to receive(:register).with(event, &a_proc)
      subject.on(event, &a_proc)
    end
    
    it "forwards to the Channel when given the channel object" do
      expect(channel).to receive(:register).with(event, &a_proc)
      subject.on(event, channel, &a_proc)
    end
    
    it "forwards to the Channel when given the channel name" do
      expect(channel).to receive(:register).with(event, &a_proc)
      subject.on(event, channel_name, &a_proc)
    end
    
    it "forwards to multiple Channels when given a channel object array" do
      expect(Wires::Channel['1']).to receive(:register).with(event, &a_proc)
      expect(Wires::Channel['2']).to receive(:register).with(event, &a_proc)
      expect(Wires::Channel['3']).to receive(:register).with(event, &a_proc)
      subject.on(event, ['1','2','3'].map{|s| Wires::Channel[s]}, &a_proc)
    end
    
    it "forwards to multiple Channels when given a channel name array" do
      expect(Wires::Channel['1']).to receive(:register).with(event, &a_proc)
      expect(Wires::Channel['2']).to receive(:register).with(event, &a_proc)
      expect(Wires::Channel['3']).to receive(:register).with(event, &a_proc)
      subject.on(event, ['1','2','3'], &a_proc)
    end
  end
  
  describe "sync_on" do
    let(:kwargs) { {timeout:55} }
    
    it "forwards to Channel[self].sync_on by default" do
      expect(Wires::Channel[subject]).to receive(:sync_on).with(event, **kwargs, &a_proc)
      subject.sync_on(event, **kwargs, &a_proc)
    end
    
    it "forwards to the Channel when given the channel object" do
      expect(channel).to receive(:sync_on).with(event, kwargs, &a_proc)
      subject.sync_on(event, channel, **kwargs, &a_proc)
    end
    
    it "forwards to the Channel when given the channel name" do
      expect(channel).to receive(:sync_on).with(event, kwargs, &a_proc)
      subject.sync_on(event, channel_name, **kwargs, &a_proc)
    end
  end
  
  describe "#fire" do
    it "forwards to Channel[self].fire by default" do
      expect(Wires::Channel[subject]).to receive(:fire).with(event, {})
      subject.fire(event)
    end
    
    it "forwards to the Channel when given the channel object" do
      expect(channel).to receive(:fire).with(event, {})
      subject.fire(event, channel)
    end
    
    it "forwards to the Channel when given the channel name" do
      expect(channel).to receive(:fire).with(event, {})
      subject.fire(event, channel_name)
    end
    
    it "forwards relevant keyword arguments" do
      kwargs = { blocking:true, parallel:true }
      expect(channel).to receive(:fire).with(event, kwargs)
      subject.fire(event, channel_name, **kwargs)
    end
  end
  
  describe "#fire!" do
    it "forwards to #fire, adding the blocking:true keyword arg" do
      expect(subject).to receive(:fire).with(1,2,3,{other:55,blocking:true})
      subject.fire!(1,2,3,other:55)
    end
    
    it "leaves the blocking keyword arg alone if it was specified" do
      expect(subject).to receive(:fire).with(1,2,3,{other:55,blocking:false})
      subject.fire!(1,2,3,other:55,blocking:false)
    end
  end
end
