
require 'wires'


module ::UserModule
  module Wires
    include ::Wires
    extend Wires::Convenience
  end
  
  Wires::Util.build_alt "::#{self}::AltWires"
  AltWires.extend AltWires::Convenience
end


describe "Wires::Util.build_alt" do
  
  it "can build an alternate version of the Wires module" do
  pending
    UserModule::Wires.constants.reject{|c| c==:Test}.each do |c|
      expect(UserModule::Wires.const_get(c)).to_not eq UserModule::AltWires.const_get(c)
    end
  end
  
  it "doesn't crosstalk when events are fired" do
  pending
    it_happened = []
    
    UserModule::Wires.on :event, 'channel' do |e|
      expect(e).to     be_a UserModule::Wires::Event
      expect(e).not_to be_a UserModule::AltWires::Event
      it_happened << UserModule::Wires
    end
    
    UserModule::AltWires.on :event, 'channel' do |e|
      expect(e).not_to be_a UserModule::Wires::Event
      expect(e).to     be_a UserModule::AltWires::Event
      it_happened << UserModule::AltWires
    end
    
    UserModule::Wires.fire    :event, 'channel'
    UserModule::AltWires.fire :event, 'channel'
    
    UserModule::Wires::Hub.join_children
    UserModule::AltWires::Hub.join_children
    
    expect(it_happened.count).to eq 2
    expect(it_happened).to include UserModule::Wires
    expect(it_happened).to include UserModule::AltWires
  end
  
end
