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

describe Wires::TimeSchedulerItem do
  include TimeTester
  
  it "creates an active item if time is in the future" do
    time = 5.seconds.from_now
    item = Wires::TimeSchedulerItem.new(time, :event)
    item.active?  .must_equal true
    item.inactive?.must_equal false
  end
  
  it "creates an active item if time is passed and ignore_past isn't used" do
    time = 5.seconds.ago
    item = Wires::TimeSchedulerItem.new(time, :event)
    item.active?  .must_equal true
    item.inactive?.must_equal false
  end
  
  it "creates an inactive item if time is passed and ignore_past is true" do
    time = 5.seconds.ago
    item = Wires::TimeSchedulerItem.new(time, :event, ignore_past:true)
    item.active?  .must_equal false
    item.inactive?.must_equal true
  end
  
  it "creates an inactive item if cancel is true" do
    time = 5.seconds.from_now
    item = Wires::TimeSchedulerItem.new(time, :event, cancel:true)
    item.active?  .must_equal false
    item.inactive?.must_equal true
  end
  
  it "knows when it is 'ready' to fire" do
    time = 0.1.seconds.from_now
    item = Wires::TimeSchedulerItem.new(time, :event, self)
    
    var = 'before'
    # on :event, 'TSI_A' do var = 'after' end
      
    sleep 0.05
    item.active?  .must_equal true
    item.inactive?.must_equal false
    item.ready?   .must_equal false
    sleep 0.1
    item.active?  .must_equal true
    item.inactive?.must_equal false
    item.ready?   .must_equal true
    item.fire
    item.active?  .must_equal false
    item.inactive?.must_equal true
    item.ready?   .must_equal false
  end
  
  it "can manually fire an event that isn't 'ready'" do
    time = 10.weeks.from_now
    item = Wires::TimeSchedulerItem.new(time, :event, self)
    
    var = 'before'
    on :event, self do var = 'after' end
      
    item.active?  .must_equal true
    item.inactive?.must_equal false
    item.ready?   .must_equal false
    
    item.fire(blocking:true)
    
    var           .must_equal 'after'
    item.active?  .must_equal false
    item.inactive?.must_equal true
    item.ready?   .must_equal false
    
  end
  
  it "can hold a repeating event" do
    time = Time.now
    count = 25
    interval = 1.seconds
    item = Wires::TimeSchedulerItem.new(time, :event, 
                                        count:count, interval:interval)
    item.active? .must_equal true
    item.count   .must_equal count
    item.interval.must_equal interval
  end
  
end


