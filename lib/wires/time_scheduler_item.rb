
module Wires
  
  class TimeSchedulerItem
    
    attr_accessor :schedulers
    attr_reader   :time, :events, :channel, 
                  :count, :interval, :jitter
    attr_accessor :fire_kwargs
    
    def initialize(time, events, channel, 
                   count:1, interval:0, jitter:0,
                   ignore_past:false, active:true,
                   **fire_kwargs)
      
      time ||= Time.now
      
      @events   = Event.new_from(events)
      @channel  = channel.is_a?(Channel) ? channel : Channel.new(channel)
      
      tempcount = count
      @interval = interval
      @jitter   = jitter
      
      @active   = active
      @fire_kwargs   = fire_kwargs
      
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

      @schedulers = []
    end
    
    def active?;   @active       end
    def active=(x) @active=x     end
    
    def ready?(at_time=Time.now)
      @active and (at_time>=@time)
    end
    
    def time_until(from_time=Time.now)
      (@active ? [(@time - from_time), 0].max : nil)
    end
    
    # Set @count (and apply constraints)
    def count=(new_count)
      @count=[new_count,0].max
        .tap { |c| @active&&=(c>0) }
    end
    
    # Inc/dec @count. Necessary because += and -= without lock are not atomic!
    def count_inc(diff=1); self.count=(@count+diff) end
    def count_dec(diff=1); self.count=(@count-diff) end
    
    # Fire the event now, regardless of time or active status
    def fire(**kwargs) # kwargs merge with and override @kwargs
      @channel.fire(@events, **(@fire_kwargs.merge kwargs))
      count_dec
      @time += @interval if @active
      notify_schedulers
    true end
    
    # Fire the event only if it is ready
    def fire_if_ready(**kwargs)
      self.fire(**kwargs) if ready?
    end
    
  private
    
    def notify_schedulers
      @schedulers.each &:refresh
    end
    
    # Lock some of the methods to try to make them atomic
    # Must exclude methods that get called from within the TimeScheduler lock
    threadlock :fire,
               :count=,
               :count_inc,
               :count_dec
  end
  
end
