require 'pry'

class TimeSchedulerEvent < Event; end
class TimeSchedulerStartEvent < TimeSchedulerEvent; end
class TimeSchedulerAnonEvent  < TimeSchedulerEvent; end

# A singleton class to schedule future firing of events
class TimeScheduler
  @schedule       = Array.new
  @schedule_lock  = Mutex.new
  @thread         = Thread.new {nil}
  @keepgoing_lock = Mutex.new
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    # Get a copy of the event schedule from outside the class
    def list;  @schedule_lock.synchronize {@schedule.clone} end
    # Clear the event schedule from outside the class
    def clear; @schedule_lock.synchronize {@schedule.clear} end
    
    # Fire an event at a specific time
    def fire(time, event, channel='*', ignore_past:false)
      if not time.is_a? Time
        raise TypeError, "Expected #{time.inspect} to be an instance of Time."
      end
      
      # Ignore past events if flag is set
      if ignore_past and time < Time.now; return nil; end
      
      # Under mutex, push the event into the schedule and sort
      @schedule_lock.synchronize do
        @schedule << {time:time, event:event, channel:channel}
        @schedule.sort! { |a,b| a[:time] <=> b[:time] }
      end
      
      # Wakeup main_loop thread if it is sleeping
      begin @thread.wakeup; rescue ThreadError; end
      
    nil end
    
  private
    
    # Do scheduled firing of events as long as Hub is alive
    def main_loop
      
      @keepgoing = true
      @thread = Thread.current
      pending = Array.new
      on_deck = nil
      
      while @keepgoing
        
        # Under mutex, pull any events that are ready into pending
        pending.clear
        @schedule_lock.synchronize do
          while ((not @schedule.empty?) and 
                 (Time.now > @schedule[0][:time]))
            pending << @schedule.shift
          end
          on_deck = @schedule[0]
        end
        
        # Fire pending events
        pending.each { |x| Channel(x[:channel]).fire(x[:event]) }
        
        # Calculate the time to sleep based on next event's time
        if on_deck
          sleep [(on_deck[:time]-Time.now), 0].max
        
        else # sleep until wakeup if no event is on deck
          @keepgoing_lock.synchronize { sleep if @keepgoing }
        
        end
        
      end
      
    nil end
    
    
  end
  
  # Use fired event to only start scheduler when Hub is running
  # This also gets the scheduler loop its own thread within the Hub's threads
  on :time_scheduler_start, self do; main_loop; end;
  Channel(self).fire(:time_scheduler_start)
  
  # Stop the main loop upon death of Hub
  Hub.before_kill(retain:true) do 
    @keepgoing_lock.synchronize do
      @keepgoing=false
      @thread.wakeup
    end
    sleep 0
  end
  # Refire the start event after Hub dies in case it restarts
  Hub.after_kill(retain:true) do 
    Channel(self).fire(:time_scheduler_start)
  end
  
  
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
      __original_since(*args).fire(:time_scheduler_anon, 
                                    block.object_id)
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
      __original_ago(*args).fire(:time_scheduler_anon, 
                                  block.object_id)
      nil
    else
      __original_ago(*args)
    end
  end
  alias :until :ago
  
end