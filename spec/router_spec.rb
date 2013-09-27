$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe Wires::Router::Default do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router.clear_channels
  end
  
  it ""
  
end


describe Wires::Router::Simple do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router.clear_channels
  end
  
  it ""
  
end