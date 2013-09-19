$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


# Module to ease testing of Time events
module TimeTester
  def teardown
    Wires::Hub.join_children
    Wires::TimeScheduler.clear
  end
end


# Time objects get extended to call TimeScheduler.add
describe "wires/core_ext::Time" do
  include TimeTester
  
  it "can now fire events at a specific time" do
    
    var = 'before'
    on :event, self do var='after' end
    0.1.seconds.from_now.fire :event, self
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "will immediately fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, self do var='after' end
    0.1.seconds.ago.fire :event, self
    sleep 0.05
    var.must_equal 'after'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "can be told not to fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, self do var='after' end
    0.1.seconds.ago.fire :event, self, ignore_past:true
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'before'
    
  end
  
end

describe "wires/core_ext::Numeric" do
end
