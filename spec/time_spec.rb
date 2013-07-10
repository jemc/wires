# require 'wires'

require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require 'hegemon'    # State machine management

require_relative '../lib/wires/expect_type'
require_relative '../lib/wires/event'
require_relative '../lib/wires/hub'
require_relative '../lib/wires/channel'
require_relative '../lib/wires/time'

require 'minitest/autorun'
require 'minitest/spec'

# Module to ease testing of Time events
module TimeTester
  def setup
    Wires::Hub.run
  end
  def teardown
    Wires::Hub.kill
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
    item = Wires::TimeSchedulerItem.new(time, :event, 'TSI_A')
    
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
    time = 10.years.from_now
    item = Wires::TimeSchedulerItem.new(time, :event, 'TSI_B')
    
    var = 'before'
    on :event, 'TSI_B' do var = 'after' end
      
    item.active?  .must_equal true
    item.inactive?.must_equal false
    item.ready?   .must_equal false
    
    item.fire(blocking:true)
    
    var           .must_equal 'after'
    item.active?  .must_equal false
    item.inactive?.must_equal true
    item.ready?   .must_equal false
    
  end
  
  it "can block until an event is 'ready', then fire it" do
    time = 0.1.seconds.from_now
    item = Wires::TimeSchedulerItem.new(time, :event, 'TSI_C')
    
    var = 'before'
    on :event, 'TSI_C' do var = 'after' end
      
    item.active?  .must_equal true
    item.inactive?.must_equal false
    item.ready?   .must_equal false
    Time.now      .must_be :<=, time
    
    item.fire_when_ready(blocking:true)
    
    Time.now      .must_be :>=, time
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

# TimeScheduler is the main time-handling object
describe Wires::TimeScheduler do
  include TimeTester
  
  it "can handle a barrage of events without dropping any" do
    
    fire_count = 50
    done_count = 0
    go_time = 0.1.seconds.from_now
    
    on :event, 'TS_A' do done_count += 1 end
    
    fire_count.times {go_time.fire :event, 'TS_A'}
    
    sleep 0.2
    
    done_count.must_equal fire_count
    
  end
  
  it "can provide a list of scheduled future events" do
  
    fire_count = 50
    done_count = 0
    go_time = 10.seconds.from_now
    
    on :event, 'TS_B' do done_count += 1 end
    
    fire_count.times {go_time.fire :event, 'TS_B'}
    
    sleep 0.05
    
    Wires::TimeScheduler.list.size.must_equal fire_count
    
  end
  
  it "can clear the scheduled future events" do
  
    fire_count = 50
    done_count = 0
    go_time = 0.1.seconds.from_now
    
    on :event, 'TS_C' do done_count += 1 end
    
    fire_count.times {go_time.fire :event, 'TS_C'}
    
    sleep 0.05
    
    Wires::TimeScheduler.clear
    Wires::TimeScheduler.list.must_be_empty
    
  end
  
  it "correctly sorts the scheduled future events" do
  
    count = 0
    
    on :event, 'TS_D' do |event|
      count += 1
      event.index.must_equal count%3
    end
    
    e = []
    3.times do |i| e << Wires::Event.new_from([:event, index:i]) end
    
    0.20.seconds.from_now.fire e[0], 'TS_D'
    0.10.seconds.from_now.fire e[1], 'TS_D'
    0.15.seconds.from_now.fire e[2], 'TS_D'
    
    sleep 0.05
    
    e << e.shift
    e.must_equal Wires::TimeScheduler.list.map { |x| x.event }
    
    sleep 0.20
    
  end
  
end
