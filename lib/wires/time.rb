

class StartSchedulerEvent < Event; end

# A singleton class to schedule future firing of events
class TimeScheduler
  @schedule      = Array.new
  @schedule_lock = Mutex.new
  @grain         = 0.2.seconds
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    # Get or set the time grain from outside the class
    attr_accessor :grain
    
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
      
    end
    
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
    end
    
  end
  
  # Use fired event to only start scheduler when Hub is running
  # This also gets the scheduler loop its own thread within the Hub's threads
  on :start_scheduler, self do; main_loop; end;
  Channel(self).fire(:start_scheduler)
end

# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class Time
  def fire(*args)
    TimeScheduler.fire(self, *args)
  end
end
