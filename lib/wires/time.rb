

class TimeSchedulerEvent < Event; end
class TimeSchedulerStartEvent < TimeSchedulerEvent; end
class TimeSchedulerAnonEvent  < TimeSchedulerEvent; end

# A singleton class to schedule future firing of events
class TimeScheduler
  @schedule      = Array.new
  @schedule_lock = Mutex.new
  @grain         = 0.2.seconds
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    # Get or set the time grain from outside the class
    attr_accessor :grain
    
    # Get a copy of the event schedule from outside the class
    def list;  @schedule_lock.synchronize {@schedule.clone} end
    # Clear the event schedule from outside the class
    def clear; @schedule_lock.synchronize {@schedule.clear} end
    
    # Fire an event delayed by time value
    def fire(time, event, channel='*')
      if not time.is_a? Time
        raise TypeError, "Expected #{time.inspect} to be an instance of Time."
      end
      
      # Under mutex, push the event into the schedule and sort
      @schedule_lock.synchronize do
        @schedule << [time, event, channel]
        @schedule.sort! { |a,b| a[0] <=> b[0] }
      end
      
    nil end
    
  private
    
    def main_loop
      
      pending = Array.new
      
      while true
        
        pending.clear
        this_time = Time.now
        
        # Under mutex, pull any events that are ready
        @schedule_lock.synchronize do
          while ((not @schedule.empty?) and (this_time > @schedule[0][0]))
            pending << @schedule.shift
          end
        end
        
        # Fire pending events
        pending.each { |x| Channel(x[2]).fire(x[1]) }
        
        # Calculate the time to sleep based on the time left in the "grain"
        sleep [@grain-(Time.now-this_time), 0].max
        
      end
    nil end
    
  end
  
  # Use fired event to only start scheduler when Hub is running
  # This also gets the scheduler loop its own thread within the Hub's threads
  on :time_scheduler_start, self do; main_loop; end;
  Channel(self).fire(:time_scheduler_start)
end


# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class Time
  def fire(*args)
    TimeScheduler.fire(self, *args)
  end
end


# Reopen ActiveSupport::Duration to enable nifty syntax like:
# 32.minutes.from_now do some_stuff end
class ActiveSupport::Duration
  
  alias :__original_since :since
  def since(*args, &block)
    if block
      on :time_scheduler_anon, block.object_id do block.call end
      __original_since(*args).fire :time_scheduler_anon, block.object_id
      nil
    else
      __original_since(*args)
    end
  end
  alias :from_now :since
  
  alias :__original_ago :ago
  def ago(*args, &block)
    if block
      on :time_scheduler_anon, block.object_id do block.call end
      __original_ago(*args).fire :time_scheduler_anon, block.object_id
      nil
    else
      __original_ago(*args)
    end
  end
  alias :until :ago
  
end