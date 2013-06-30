require 'wires'

require 'minitest/spec'
require 'minitest/autorun'

# Module to ease testing of Time events
module TimeTester
  def setup;    Hub.run;              end
  def teardown; Hub.kill :blocking, 
                         :finish_all;
                TimeScheduler.clear;  end
end

# Time objects get extended to call TimeScheduler.fire
describe Time do
  include TimeTester
  
  it "can now fire events at a specific time" do
    
    var = 'before'
    on :event, 'T_A' do var='after' end
    0.1.seconds.from_now.fire :event
    sleep 0.05
    var.must_equal 'before'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "will immediately fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, 'T_B' do var='after' end
    0.1.seconds.ago.fire :event
    sleep 0.05
    var.must_equal 'after'
    sleep 0.15
    var.must_equal 'after'
    
  end
  
  it "can be told not to fire events aimed at a time in the past" do
    
    var = 'before'
    on :event, 'T_C' do var='after' end
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
  
end

describe TimeScheduler do
  include TimeTester
  
  # it "can handle a barrage of events without dropping any" do
    
  #   fire_count = 25
  #   done_count = 0
  #   go_time = 0.2.seconds.from_now
    
  #   on :event, 'TS_A' do done_count += 1 end
    
  #   fire_count.times {go_time.fire :event, 'TS_A'}
    
  #   until TimeScheduler.list.empty?
  #     sleep 0.1; end
  #   done_count.must_equal fire_count
    
  # end
  
end
