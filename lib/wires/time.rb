
# TODO: do not start TimeScheduler thread until first TimeSchedulerItem

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
      @channel  = Channel.new(channel) unless channel.is_a? Channel
      @kwargs   = kwargs
    end
    
    def active?;        @active                                      end
    def inactive?;      not @active                                  end
    
    def ready?(at_time=Time.now); @active and at_time and (at_time>=@time) end
    
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
    @dont_sleep     = false
    
    @grain = 1.seconds
    
    # Operate on the metaclass as a type of singleton pattern
    class << self
      
      attr_accessor :grain
      
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
      def list;  @schedule.clone end
      # Clear the event schedule from outside the class
      def clear; schedule_clear end
      
    private
    
      def schedule_clear
        @schedule.clear
      end
    
      def schedule_reshuffle
        @schedule.select! {|x| x.active?}
        @schedule.sort! {|a,b| a.time <=> b.time}
      nil end
      
      def schedule_add(new_item)
        
        if @keepgoing
          if new_item.ready?
            loop do
              new_item.fire
              break unless new_item.ready?
            end
          end
          
          if new_item.ready?(@next_pass)
            Thread.new do
              loop do
                new_item.fire_when_ready(blocking:true)
                break unless new_item.ready?(@next_pass)
              end
            end
          end
        end
        
        @schedule << new_item
        schedule_reshuffle
        
      nil end
      
      def schedule_concat(other_list)
        @schedule.concat other_list
        schedule_reshuffle
      nil end
      
      def schedule_pull
        pending_now  = Array.new
        pending_soon = Array.new
        while ((not @schedule.empty?) and @schedule[0].ready?)
          pending_now << @schedule.shift
        end
        while ((not @schedule.empty?) and @schedule[0].ready?(@next_pass))
          pending_soon << @schedule.shift
        end
        return [pending_now, pending_soon]
      end
      
      def schedule_next_pass
        @next_pass = Time.now+@grain
      end
      
      # Put all functions dealing with @schedule under @schedule_lock
      threadlock :list,
                 :schedule_clear,
                 :schedule_reshuffle,
                 :schedule_add,
                 :schedule_concat,
                 :schedule_pull,
                 :schedule_next_pass,
           lock: :@schedule_lock
      
      def main_loop
        
        # @keepgoing = true
        pending = Array.new
        on_deck = nil
        
        while @keepgoing
          
          schedule_next_pass
          
          # Pull, fire, and requeue relevant events
          pending_now, pending_soon = schedule_pull
          pending_now.each { |x| x.fire }
          pending_soon.each{ |x| Thread.new{ x.fire_when_ready(blocking:true) }}
          # schedule_concat pending_now
          
          sleep [@next_pass-Time.now, 0].max
        end
        
      nil end
      
    end
    
  end
  
end
