
module Wires
  
  class TimeSchedulerStartEvent < Event; end
  class TimeSchedulerAnonEvent  < Event; end
  
  
  class TimeSchedulerItem
    
    attr_reader :time, :event, :channel, :interval
    
    def initialize(time, event, channel='*', 
                   interval:0.seconds, count:1, 
                   ignore_past:false, cancel:false)
      
      expect_type time, Time
      
      @active = (not cancel)
      tempcount = count
      
      while (time < Time.now) and (tempcount > 0)
        time += interval
        tempcount -= 1
      end
      if not ignore_past
        time -= interval
        self.count = count
      else
        self.count = tempcount
      end
      
      @time     = time
      @event    = Event.new_from(event)
      @channel  = channel
      @interval = interval
      
    end
    
    def active?;        @active                                      end
    def inactive?;      not @active                                  end
    def ready?;         @active and (Time.now >= @time)              end
    def time_until;    (@active ? [(Time.now - @time), 0].max : nil) end
    
    def cancel;         @active = false                         ;nil end
    
    # Get/set @count (and apply constraints on set)
    def count;          @count                                       end
                                          #TODO: handle explicit cancel?
    def count=(x);      @count=[x,0].max; @active&&=(count>0)   ;nil end
    
    # Inc/dec @count. Necessary because += and -= outside of lock are not atomic!
    def count_inc(x=1); self.count=(@count+x)                        end
    def count_dec(x=1); self.count=(@count-x)                        end
    
    # Fire the event now, regardless of time or active status
    def fire(*args)
      Channel.new(@channel).fire(@event, *args)
      count_dec
      @time += @interval if @active
    nil end
    
    # Fire the event only if it is ready
    def fire_if_ready(*args); self.fire(*args) if ready? end
    
    # Block until event is ready
    def wait_until_ready; sleep 0 until ready? end
    
    # Block until event is ready, then fire and block until it is done
    def fire_when_ready(*args);
      wait_until_ready
      fire_if_ready(*args)
    end
    
    # Lock (almost) all instance methods with common re-entrant lock
    threadlock instance_methods-superclass.instance_methods-[
                                :block_until_ready,
                                :fire_when_ready]
  end
  
  # A singleton class to schedule future firing of events
  class TimeScheduler
    @schedule       = Array.new
    @thread         = Thread.new {nil}
    @schedule_lock  = Monitor.new
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
      
      def main_loop
        
        @keepgoing = true
        pending = Array.new
        on_deck = nil
        
        while @keepgoing
          
          # Pull, fire, and requeue relevant events
          pending, on_deck = schedule_pull
          pending.each { |x| x.fire }
          schedule_concat pending
          
          @sleepzone = true
          # Calculate the time to sleep based on next event's time
          if on_deck
            sleep on_deck.time_until
          else # sleep until wakeup if no event is on deck
            sleep
          end
          @sleepzone = false
        end
        
      nil end
      
      def wakeup
        sleep 0 until @sleepzone==true
        sleep 0 until @thread.status=='sleep'
        @thread.wakeup
      nil end
      
    end
    
    # Use fired event to only start scheduler when Hub is running
    # This also gets the scheduler loop its own thread within the Hub's threads
    # on :time_scheduler_start, self do; main_loop; end;
    # Channel.new(self).fire(:time_scheduler_start)
    
    # Refire the start event after Hub dies in case it restarts
    Hub.after_run(retain:true) do 
      @thread = Thread.new { main_loop }
    end
    
    # Stop the main loop upon death of Hub
    Hub.before_kill(retain:true) do 
      sleep 0 until @sleepzone==true
      sleep 0 until @thread.status=='sleep'
      @keepgoing=false
      wakeup
      @thread.join
    end
    
  end
  
end # End Wires module.

# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class Time
  def fire(event, channel='*', **kwargs)
    Wires::TimeScheduler << \
      Wires::TimeSchedulerItem.new(self, event, channel, **kwargs)
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