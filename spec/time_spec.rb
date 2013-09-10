$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

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


# TimeScheduler is the main time-handling object
describe Wires::TimeScheduler do
  include TimeTester
  
  it "can accept an existing TimeSchedulerItem with .add" do
    item = Wires::TimeSchedulerItem.new(5.hours.from_now, :event, 
                                        interval:3.seconds, count:50)
    Wires::TimeScheduler.add item
    Wires::TimeScheduler.list.size.must_equal 1
    Wires::TimeScheduler.list.must_include item
  end
  
  it "can accept an existing TimeSchedulerItem with .<<" do
    item = Wires::TimeSchedulerItem.new(5.hours.from_now, :event, 
                                        interval:3.seconds, count:50)
    Wires::TimeScheduler << item
    Wires::TimeScheduler.list.size.must_equal 1
    Wires::TimeScheduler.list.must_include item
  end
  
  it "can create a new TimeSchedulerItem with .add" do
    Wires::TimeScheduler.add(5.hours.from_now, :event, 
                             interval:3.seconds, count:50)
    Wires::TimeScheduler.list.size.must_equal 1
    Wires::TimeScheduler.list[0].interval.must_equal 3.seconds
    Wires::TimeScheduler.list[0].count   .must_equal 50
  end
  
  it "can create a new TimeSchedulerItem with .<<" do
    Wires::TimeScheduler << [5.hours.from_now, :event, 
                             interval:3.seconds, count:50]
    Wires::TimeScheduler.list.size.must_equal 1
    Wires::TimeScheduler.list[0].interval.must_equal 3.seconds
    Wires::TimeScheduler.list[0].count   .must_equal 50
  end
  
  it "can handle a barrage of events without dropping any" do
    
    fire_count = 50
    done_count = 0
    go_time = 0.1.seconds.from_now
    
    on :event, 'TS_A' do done_count += 1 end
    
    fire_count.times do
      Wires::TimeScheduler.add go_time, :event, 'TS_A'
    end
    
    sleep 0.2
    
    done_count.must_equal fire_count
    
  end
  
  it "can provide a list of scheduled future events" do
  
    fire_count = 50
    done_count = 0
    go_time = 10.seconds.from_now
    
    on :event, 'TS_B' do done_count += 1 end
    
    fire_count.times do
      Wires::TimeScheduler.add go_time, :event, 'TS_B'
    end
    
    sleep 0.05
    
    Wires::TimeScheduler.list.size.must_equal fire_count
    
  end
  
  it "can clear the scheduled future events" do
  
    fire_count = 50
    done_count = 0
    go_time = 10.hours.from_now
    
    on :event, 'TS_C' do done_count += 1 end
    
    fire_count.times do
      Wires::TimeScheduler.add go_time, :event, 'TS_C'
    end
    
    sleep 0.05
    
    Wires::TimeScheduler.list.wont_be_empty
    Wires::TimeScheduler.clear
    Wires::TimeScheduler.list.must_be_empty
    
  end
  
  it "correctly sorts the scheduled future events" do
  
    count = 0
    
    e = []
    3.times do |i| e << Wires::Event.new_from([:event, index:i]) end
    
    Wires::TimeScheduler << [3.hours.from_now, e[0], 'TS_D']
    Wires::TimeScheduler << [1.hours.from_now, e[1], 'TS_D']
    Wires::TimeScheduler << [2.hours.from_now, e[2], 'TS_D']
    
    e << e.shift
    e.must_equal Wires::TimeScheduler.list.map { |x| x.event }
    
  end
  
end


