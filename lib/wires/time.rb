
# TODO: do not start TimeScheduler thread until first TimeSchedulerItem
# TODO: stop TimeScheduler thread when there are no future events

module Wires
  
  class TimeSchedulerAnonEvent  < Event; end
  
  class TimeSchedulerItem
    
    attr_reader :time, :event, :channel, :interval
    
    def initialize(time, event, channel='*', 
                   interval:0.seconds, count:1, 
                   ignore_past:false, cancel:false,
                   **kwargs)
      
      time ||= Time.now
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
      @interval = interval
      
      @event    = Event.new_from(event)
      @channel  = channel.is_a?(Channel) ? channel : Channel.new(channel)
      @kwargs   = kwargs
    end
    
    def active?;        @active                                      end
    def inactive?;      not @active                                  end
    
    def ready?(at_time=Time.now); @active and at_time and (at_time>=@time) end
    
    def time_until;    (@active ? [(@time - Time.now), 0].max : nil) end
    
    def cancel;         @active = false                         ;nil end
    
    # Get/set @count (and apply constraints on set)
    def count;          @count                                       end
                                          #TODO: handle explicit cancel?
    def count=(x);      @count=[x,0].max; @active&&=(count>0)   ;nil end
    
    # Inc/dec @count. Necessary because += and -= outside of lock are not atomic!
    def count_inc(x=1); self.count=(@count+x)                        end
    def count_dec(x=1); self.count=(@count-x)                        end
    
    # Fire the event now, regardless of time or active status
    def fire(**kwargs) # kwargs merge with and override @kwargs
      @channel.fire(@event, **(@kwargs.merge(kwargs)))
      count_dec
      @time += @interval if @active
    nil end
    
    # Fire the event only if it is ready
    def fire_if_ready(**args); self.fire(**kwargs) if ready? end
    
    # Block until event is ready
    def wait_until_ready; sleep 0 until ready? end
    
    # Block until event is ready, then fire and block until it is done
    def fire_when_ready(**kwargs);
      wait_until_ready
      self.fire(**kwargs)
    end
    
    # Lock (almost) all instance methods with common re-entrant lock
    threadlock instance_methods(false)-[\
                 :wait_until_ready,
                 :fire_when_ready]
  end
  
  # A singleton class to schedule future firing of events
  class TimeScheduler
    @schedule       = Array.new
    @thread         = Thread.new {nil}
    @schedule_lock  = Monitor.new
    @cond           = @schedule_lock.new_cond
    
    class << self
      
      # Add an event to the schedule
      def add(*args)
        new_item = (args.first.is_a? TimeSchedulerItem) ?
                     (args.first) :
                     (TimeSchedulerItem.new(*args))
        schedule_add(new_item)
      nil end
      
      # Add an event to the schedule using << operator
      def <<(arg); add(*arg); end
      
      # Get a copy of the event schedule from outside the class
      def list;   @schedule.dup end
      # Clear the event schedule from outside the class
      def clear;   schedule_clear end
      # Make the scheduler wake up and re-evaluate
      def refresh; schedule_refresh end
      
    private
    
      def schedule_clear
        @schedule.clear
      nil end
    
      def schedule_reshuffle
        @schedule.select! {|x| x.active?}
        @schedule.sort! {|a,b| a.time <=> b.time}
      nil end
      
      def schedule_refresh
        schedule_reshuffle
        @cond.signal
      nil end
      
      def schedule_add(new_item)
        @schedule << new_item
        refresh
      nil end
      
      def schedule_pull
        pending  = []
        while ((not @schedule.empty?) and @schedule.first.ready?)
          pending << @schedule.shift
        end
        pending
      end
      
      # Put all functions dealing with @schedule under @schedule_lock
      threadlock :list,
                 :schedule_clear,
                 :schedule_reshuffle,
                 :schedule_refresh,
                 :schedule_add,
                 :schedule_pull,
           lock: :@schedule_lock
      
      def main_loop
        pending = []
        loop do
          @schedule_lock.synchronize do
            @cond.wait((@schedule.first.time_until unless @schedule.empty?))
            pending = schedule_pull
          end
          pending.each &:fire
        end
      nil end
      
    end
    
    @thread = Thread.new { main_loop }
    
  end
  
end
