require 'wires'
# require_relative 'wires-devel'

require 'minitest/autorun'
require 'minitest/spec'
# require 'turn'
# Turn.config.format  = :outline
# Turn.config.natural = true
# Turn.config.trace   = 5


module Wires
  def self.build_alt
    alt = Module.new
    for cls in self.constants
      case const_get(cls)
      when Class
        # alt.send(:remove_const, cls) if self.const_defined? cls
        alt.send(:const_set, cls, Class.new(const_get(cls)))
      when Module
        # alt.send(:remove_const, cls) if self.const_defined? cls
        alt.send(:const_set, cls, const_get(cls).clone)
      end
    end
    alt
  end
end

SysWires = Wires.build_alt

describe 'Wires.build_alt' do
  
  it "builds a distinct module" do
    Wires.object_id.wont_equal SysWires.object_id
  end
  
  Wires.constants.each do |c|
code = <<CODE
    it "builds a distinct inner #{c}" do
      Wires::#{c}.object_id.wont_equal SysWires::#{c}.object_id
    end
CODE
    eval(code)
  end
  
  it "builds Channels that point to a distinct Hub" #do
  #   p Wires::Channel.hub.object_id
  #   p SysWires::Channel.hub.object_id
  # end
  
end