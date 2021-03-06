
module Wires.current_network::Namespace
  
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
      
      @events   = Event.list_from(events)
      @channel  = channel.is_a?(Channel) ? channel : Channel.new(channel)
      
      @interval = interval
      @jitter   = jitter
      
      @active   = active
      @fire_kwargs   = fire_kwargs
      
      tempcount = count
      if ignore_past
        while (time < Time.now) and (tempcount > 0)
          time += interval
          tempcount -= 1
        end
      end
      self.count = tempcount
      
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
      kwargs = @fire_kwargs.merge kwargs
      @events.each { |e| @channel.fire(e, **kwargs) }
      count_dec
      
      if @active
        @time = [@time, Time.now].max + (@interval + (Random.rand*2-1)*@jitter)
      end
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
    include Threadlock
    threadlock :fire,
               :count=,
               :count_inc,
               :count_dec
  end
  
end
