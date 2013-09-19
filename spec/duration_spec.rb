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


# Duration objects help with syntax sugar and can fire anonymous event blocks
describe "wires/core_ext::Wires::Duration" do
  include TimeTester
  
  it "can now fire timed anonymous events, given a code block" do
    
    var = 'before'
    0.1.seconds.from_now do 
      var = 'after'
    end
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "can now fire anonymous events at at time related to another time" do
    var = 'before'
    0.1.seconds.until(0.2.seconds.from_now) do 
      var = 'after'
    end
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "can now fire timed anonymous events, which don't match with eachother" do
    
    fire_count = 20
    done_count = 0
    past_events = []
    
    for i in 0...fire_count
      (i*0.01+0.1).seconds.from_now do |event|
        done_count += 1
        past_events.wont_include event
        past_events << event
      end
    end
    
    sleep (fire_count*0.01+0.2)
    
    done_count.must_equal fire_count
    
  end
  
end