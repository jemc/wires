
# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class ::Time
  unless instance_methods.include? :fire
    def fire(event, channel='*', **kwargs)
      Wires::TimeScheduler << \
        Wires::TimeSchedulerItem.new(self, event, channel, **kwargs)
    end
  end
end


# Reopen ActiveSupport::Duration to enable nifty syntax like:
# 32.minutes.from_now do some_stuff end
class ::ActiveSupport::Duration
  
  unless instance_methods.include? :__original_since
    alias_method :__original_since, :since
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
  end
  
  unless instance_methods.include? :__original_ago
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
  
end