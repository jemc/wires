
require 'wires'

require 'spec_helper'


module UserModule
  $the_altwires_module = ::Wires::Util.build_alt "::#{self}::AltWires"
  Wires = ::Wires
end


describe "wires/base/util/build_alt" do
  
  describe "creates a module which" do
    subject       { ::UserModule::AltWires }
    let(:event)   { ::UserModule::AltWires::Event.new }
    let(:channel) { ::UserModule::AltWires::Channel['name'] }
    
    let(:wires_event)   { Wires::Event.new }
    let(:wires_channel) { Wires::Channel['name'] }
    
    # Get a list of constants in Wires, recursive 10 levels deep
    let(:wires_constants) do
      array = [Wires]
      
      10.times do
        ary = []
        array.each do |obj|
          ary += obj.constants.map { |sym| obj.const_get(sym) }
        end
        (array += ary).uniq!
      end
      
      array - [Wires]
    end
    
    it "is the return value of the build_alt method" do
      expect($the_altwires_module).to eq subject
    end
    
    it "contains an alternate version of each Wires singleton" do
      wires_constants.reject{|obj| obj.respond_to? :new}.each do |obj|
        alt_obj = eval obj.to_s.gsub(/^Wires/, subject.to_s)
        expect(alt_obj).to_not equal obj
      end
    end
    
    it "doesn't crosstalk when events are fired" do
      main_obj = Object.new.tap{|x| x.extend UserModule::Wires::Convenience}
      alt_obj  = Object.new.tap{|x| x.extend UserModule::AltWires::Convenience}
      
      it_happened = []
      
      main_obj.on :event, 'chan_name' do |e|
        it_happened << UserModule::Wires
      end
      
      alt_obj.on :event, 'chan_name' do |e|
        it_happened << UserModule::AltWires
      end
      
      main_obj.fire :event, 'chan_name'
      alt_obj .fire :event, 'chan_name'
      
      UserModule::Wires::Hub.join_children
      UserModule::AltWires::Hub.join_children
      
      expect(it_happened.count).to eq 2
      expect(it_happened).to include UserModule::Wires
      expect(it_happened).to include UserModule::AltWires
    end
    
  end
end
