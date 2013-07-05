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

describe TimeSchedulerItem do
  include TimeTester
  
  it "creates an active item if time is in the future" do
    time = 5.seconds.from_now
    item = TimeSchedulerItem.new(time, :event)
    item.active?  .must_equal true
    item.inactive?.must_equal false
  end
  
  it "creates an active item if time is passed and ignore_past isn't used" do
    time = 5.seconds.ago
    item = TimeSchedulerItem.new(time, :event)
    item.active?  .must_equal true
    item.inactive?.must_equal false
  end
  
  it "creates an inactive item if time is passed and ignore_past is true" do
    time = 5.seconds.ago
    item = TimeSchedulerItem.new(time, :event, ignore_past:true)
    item.active?  .must_equal false
    item.inactive?.must_equal true
  end
  
  it "creates an inactive item if cancel is true" do
    time = 5.seconds.from_now
    item = TimeSchedulerItem.new(time, :event, cancel:true)
    item.active?  .must_equal false
    item.inactive?.must_equal true
  end
  
end


# # Time objects get extended to call TimeScheduler.fire
# describe Time do
#   include TimeTester
  
#   it "can now fire events at a specific time" do
    
#     var = 'before'
#     on :event, 'T_A' do var='after' end
#     0.1.seconds.from_now.fire :event
#     sleep 0.05
#     var.must_equal 'before'
#     sleep 0.15
#     var.must_equal 'after'
    
#   end
  
#   it "will immediately fire events aimed at a time in the past" do
    
#     var = 'before'
#     on :event, 'T_B' do var='after' end
#     0.1.seconds.ago.fire :event
#     sleep 0.05
#     var.must_equal 'after'
#     sleep 0.15
#     var.must_equal 'after'
    
#   end
  
#   it "can be told not to fire events aimed at a time in the past" do
    
#     var = 'before'
#     on :event, 'T_C' do var='after' end
#     0.1.seconds.ago.fire :event, ignore_past:true
#     sleep 0.05
#     var.must_equal 'before'
#     sleep 0.15
#     var.must_equal 'before'
    
#   end
  
# end

# # Duration objects get extended to fire anonymous event blocks
# describe ActiveSupport::Duration do
#   include TimeTester
  
#   it "can now fire timed anonymous events, given a code block" do
    
#     var = 'before'
#     0.1.seconds.from_now do 
#       var = 'after'
#     end
#     sleep 0.05
#     var.must_equal 'before'
#     sleep 0.15
#     var.must_equal 'after'
    
#   end
  
#   it "can now fire anonymous events at at time related to another time" do
#     var = 'before'
#     0.1.seconds.until(0.2.seconds.from_now) do 
#       var = 'after'
#     end
#     sleep 0.05
#     var.must_equal 'before'
#     sleep 0.15
#     var.must_equal 'after'
    
#   end
  
#   it "can now fire timed anonymous events, which don't match with eachother" do
    
#     fire_count = 20
#     done_count = 0
#     past_events = []
    
#     for i in 0...fire_count
#       (i*0.01+0.1).seconds.from_now do |event|
#         done_count += 1
#         past_events.wont_include event
#         past_events << event
#       end
#     end
    
#     sleep (fire_count*0.01+0.2)
    
#     done_count.must_equal fire_count
    
#   end
  
# end

# # TimeScheduler is the main time-handling object
# describe TimeScheduler do
#   include TimeTester
  
#   it "can handle a barrage of events without dropping any" do
    
#     fire_count = 50
#     done_count = 0
#     go_time = 0.1.seconds.from_now
    
#     on :event, 'TS_A' do done_count += 1 end
    
#     fire_count.times {go_time.fire :event, 'TS_A'}
    
#     sleep 0.2
    
#     done_count.must_equal fire_count
    
#   end
  
#   it "can provide a list of scheduled future events" do
  
#     fire_count = 50
#     done_count = 0
#     go_time = 0.1.seconds.from_now
    
#     on :event, 'TS_B' do done_count += 1 end
    
#     fire_count.times {go_time.fire :event, 'TS_B'}
    
#     sleep 0.05
    
#     TimeScheduler.list.size.must_equal fire_count
    
#   end
  
#   it "can clear the scheduled future events" do
  
#     fire_count = 50
#     done_count = 0
#     go_time = 0.1.seconds.from_now
    
#     on :event, 'TS_D' do done_count += 1 end
    
#     fire_count.times {go_time.fire :event, 'TS_D'}
    
#     sleep 0.05
    
#     TimeScheduler.clear
#     TimeScheduler.list.must_be_empty
    
#   end
  
#   it "correctly sorts the scheduled future events" do
  
#     count = 0
    
#     on :event, 'TS_C' do |event|
#       count += 1
#       event.index.must_equal count%3
#     end
    
#     e = []
#     3.times do |i| e << [:event, index:i] end
    
#     0.20.seconds.from_now.fire e[0], 'TS_C'
#     0.10.seconds.from_now.fire e[1], 'TS_C'
#     0.15.seconds.from_now.fire e[2], 'TS_C'
    
#     sleep 0.05
    
#     e << e.shift
#     e.must_equal TimeScheduler.list.map { |x| x.event }
    
#     sleep 0.20
    
#   end
  
# end
