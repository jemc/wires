$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe "wires/convenience" do
  
  describe "#Channel" do
    it "is an alias for Channel.new" do
      Wires::Channel.new('new').must_equal Channel('new')
    end
  end
  
end