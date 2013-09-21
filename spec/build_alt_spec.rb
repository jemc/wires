$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'minitest/autorun'
begin require 'jemc/reporter'; rescue LoadError; end


module BuildAltTestHelper
  def setup
    eval <<-'CODE'
      module ::UserModule
        Wires::Util.build_alt "::#{self}::AltWires"
        AltWires.extend AltWires::Convenience
      end
    CODE
  end
end


describe "wires/util/build_alt" do
  include BuildAltTestHelper
  
  it "can build an alternate version of the Wires module" do
    module UserModule
      Wires.constants.reject{|c| c==:Test}.each do |c|
        Wires.const_get(c).wont_equal AltWires.const_get(c)
      end
    end
  end
  
  it "doesn't crosstalk when events are fired" do
    module UserModule
      it_happened = []
      
      on :event, 'channel' do |e|
        e.must_be_instance_of Wires::Event
        e.wont_be_instance_of AltWires::Event
        it_happened << Wires
      end
      
      AltWires.on :event, 'channel' do |e|
        e.wont_be_instance_of Wires::Event
        e.must_be_instance_of AltWires::Event
        it_happened << AltWires
      end
      
      fire          :event, 'channel'
      AltWires.fire :event, 'channel'
      
      Wires::Hub.join_children
      AltWires::Hub.join_children
      
      it_happened.count.must_equal 2
      it_happened.must_include Wires
      it_happened.must_include AltWires
    end
  end
  
end