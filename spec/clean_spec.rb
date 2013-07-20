require 'wires'
# require_relative 'wires-devel'

require 'minitest/spec'
require 'minitest/autorun'

_main = self

describe 'wires/clean' do
  
  it 'unincludes methods from the WiresConvenience module' do
  
    list = Wires::Convenience.instance_methods(false)
    list.select { |sym| _main.respond_to?(sym) }.must_equal list
    
    require 'wires/clean'
    
    list.select { |sym| _main.respond_to?(sym) }.must_be_empty
    
  end
  
end
