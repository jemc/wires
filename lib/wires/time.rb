
class TimeSchedulerStartEvent < Event; end
class TimeSchedulerAnonEvent  < Event; end


# TODO: add repeat_count kwarg
class TimeSchedulerItem
  
  attr_reader :time, :event, :channel, :repeat
  
  def initialize(time, event, channel='*', repeat:nil, ignore_past:false)
    
    expect_type time, Time
    
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
  @thread         = Thread.new {nil}
  @schedule_lock  = Monitor.new
  @keepgoing_lock = Mutex.new
  @dont_sleep     = false
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    # Add an event to the schedule
    def add(new_item)
      expect_type new_item, TimeSchedulerItem
      schedule_add(new_item)
      wakeup
    nil end
    # Add an event to the schedule using << operator
    alias_method :<<, :add
    
    # Get a copy of the event schedule from outside the class
    def list;  @schedule.clone end
    # Clear the event schedule from outside the class
    def clear; @schedule.clear end
    
  private
  
    def schedule_reshuffle
      @schedule.select! {|x| x.active?}
      @schedule.sort! {|a,b| a.time <=> b.time}
    nil end
    
    def schedule_add(new_item)
      @schedule << new_item
      schedule_reshuffle
    nil end
    
    def schedule_concat(other_list)
      @schedule.concat other_list
      schedule_reshuffle
    nil end
    
    def schedule_pull
      pending = Array.new
      while ((not @schedule.empty?) and @schedule[0].ready?)
        pending << @schedule.shift
      end
      [pending, @schedule[0]]
    end
    
    # Put all functions dealing with @schedule under @schedule_lock
    threadlock :list,
               :clear,
               :schedule_reshuffle,
               :schedule_add,
               :schedule_concat,
               :schedule_pull,
         lock: :@schedule_lock
    
    # Do scheduled firing of events as long as Hub is alive
    def main_loop
      
      @keepgoing = true
      @thread = Thread.current
      pending = Array.new
      on_deck = nil
      
      while @keepgoing
        
        # Pull, fire, and requeue relevant events
        pending, on_deck = schedule_pull
        pending.each { |x| x.fire }
        schedule_concat pending
        
        # TODO - properly handle sleep/wakeup thread safety
        # Calculate the time to sleep based on next event's time
        if on_deck
          sleep on_deck.time_until
        else # sleep until wakeup if no event is on deck
          sleep unless @dont_sleep
          @dont_sleep = false
        end
        
      end
      
    nil end
    
    def wakeup
      begin @thread.wakeup
      rescue ThreadError; @dont_sleep=true
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
      wakeup
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