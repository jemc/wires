require 'wires'

require 'minitest/spec'
require 'minitest/autorun'

# Module to ease testing of Time events
module TimeTester
  def setup;    Hub.run;              end
  def teardown; Hub.kill_and_wait;    
                TimeScheduler.clear;  end
end

# Time objects get extended to call TimeScheduler.fire
describe Time do
  include TimeTester
  
  it "can now fire events at a specific time" do
    
    var = 'before'
    on :event, 'testA' do var='after' end
    0.1.seconds.from_now.fire :event
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "will immediately fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, 'testB' do var='after' end
    0.1.seconds.ago.fire :event
    sleep 0.05
    var.must_equal 'after'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "can be told not to fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, 'testB' do var='after' end
    0.1.seconds.ago.fire :event, ignore_past:true
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'before'
    
  end
  
end

# Duration objects get extended to fire anonymous event blocks
describe ActiveSupport::Duration do
  include TimeTester
  
  it "can now fire timed anonymous events, given a code block" do
    
    var = 'before'
    0.2.seconds.from_now do 
      var = 'after'
    end
    sleep 0.1
    var.must_equal 'before'
    sleep 0.3
    var.must_equal 'after'
    
    teardown; setup
    
    var = 'before'
    0.2.seconds.until(0.4.seconds.from_now) do 
      var = 'after'
    end
    sleep 0.1
    var.must_equal 'before'
    sleep 0.3
    var.must_equal 'after'
    
  end
  
end
