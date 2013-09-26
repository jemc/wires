
module Wires
  
  class TimeSchedulerItem
    
    attr_reader :time, :event, :channel, :interval
    attr_accessor :schedulers
    
    def initialize(time, event, channel='*', 
                   interval:0.seconds, count:1, 
                   ignore_past:false, cancel:false,
                   **kwargs)
      
      time ||= Time.now
      
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
      
      @schedulers = []
    end
    
    def active?;        @active                                      end
    def inactive?;     !@active                                      end
    
    def ready?(at_time=Time.now);  @active and (at_time>=@time)      end
    
    def time_until;    (@active ? [(@time - Time.now), 0].max : nil) end
    
    def cancel;         self.count=0                            ;nil end
    
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
      notify_schedulers
    nil end
    
    # Fire the event only if it is ready
    def fire_if_ready(**args); self.fire(**kwargs) if ready? end
    
  private
    
    def notify_schedulers; @schedulers.each &:refresh                end
    
    # Lock some of the methods to try to make them atomic
    # Must exclude methods that get called from within the TimeScheduler lock
    threadlock :fire,
               :count=,
               :count_inc,
               :count_dec
  end
  
end
