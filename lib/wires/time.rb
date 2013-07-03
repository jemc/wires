
class TimeSchedulerStartEvent < Event; end
class TimeSchedulerAnonEvent  < Event; end


# TODO: add repeat_count kwarg
class TimeSchedulerItem
  
  attr_reader :time, :event, :channel, :repeat
  
  def initialize(time, event, channel='*', repeat:nil, ignore_past:false)
    
    unless time.is_a? Time
      raise TypeError, "Expected #{time.inspect} to be an instance of Time."
    end
    
    @active = true
    
    if repeat
      while (time < Time.now)
        time += repeat
      end
      time -= repeat unless ignore_past
    else
      @active = false if (ignore_past and (time < Time.now))
    end
    
    @time    = time
    @event   = event
    @channel = channel
    @repeat  = repeat
    
  end
  
  def active?;     @active                                      end
  def inactive?;   not @active                                  end
  def ready?;      @active and (Time.now >= @time)              end
  def time_until; (@active ? [(Time.now - @time), 0].max : nil) end
  
  def cancel;      @active = false                        ;nil  end
  
  def fire
    Channel.new(@channel).fire(@event)
    (@repeat ? @time += @repeat : @active = false)
  nil end
  
  # Lock all instance methods with common re-entrant lock
  threadlock instance_methods-superclass.instance_methods
end

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
    
    # Add an event to the schedule
    def add(new_item)
      
      # TODO: create generic global expect_type(x, type) function
      unless new_item.is_a? TimeSchedulerItem
        raise TypeError, "Expected #{new_item.inspect} to be an instance of Time."
      end
      
      # Under mutex, push the event into the schedule and sort
      @schedule_lock.synchronize do
        @schedule << new_item
        schedule_reshuffle
      end
      
      # Wakeup main_loop thread if it is sleeping
      begin @thread.wakeup; rescue ThreadError; end
      
    nil end
    
    # Add an event to the schedule using << operator
    alias_method :<<, :add
    
  private
  
    def schedule_reshuffle
      @schedule.select! {|x| x.active?}
      @schedule.sort! {|a,b| a.time <=> b.time}
    end
    
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
          while ((not @schedule.empty?) and @schedule[0].ready?)
            pending << @schedule.shift
          end
          on_deck = @schedule[0]
        end
        
        # Fire pending events
        pending.each { |x| x.fire }
        
        # Requeue pending events (in case they are repeating) and reshuffle
        @schedule_lock.synchronize do 
          @schedule.concat pending
          schedule_reshuffle
        end
        
        # TODO - properly handle sleep/wakeup thread safety
        # Calculate the time to sleep based on next event's time
        if on_deck
          sleep on_deck.time_until
        else # sleep until wakeup if no event is on deck
          sleep if @keepgoing
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
  def fire(event, channel='*', **kwargs)
    TimeScheduler << TimeSchedulerItem.new(self, event, channel, **kwargs)
  end
end


# Reopen ActiveSupport::Duration to enable nifty syntax like:
# 32.minutes.from_now do some_stuff end
class ActiveSupport::Duration
  
  alias :__original_since :since
  def since(*args, &block)
    if block
      on :time_scheduler_anon, block.object_id do |e| block.call(e) end
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
      on :time_scheduler_anon, block.object_id do |e| block.call(e) end
      __original_ago(*args).fire(:time_scheduler_anon, 
                                  block.object_id)
      nil
    else
      __original_ago(*args)
    end
  end
  alias :until :ago
  
end


# TODO: Repeatable event sugar?
# TODO: Tests for all new functionality