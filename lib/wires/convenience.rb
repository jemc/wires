
module Wires

  module Convenience
    
    def on(events, channels='*', &codeblock)
      [*channels].each do |channel|
        channel=Channel.new(channel) unless channel.is_a? Channel
        
        channel.register(*events, &codeblock)
      end
      codeblock
    end
    
    def fire(event, channels='*', **kwargs)
      [*channels].each do |channel|
        channel = Channel.new(channel) unless channel.is_a? Channel
        
        if kwargs[:time] or (kwargs[:count] and kwargs[:count]!=1)
          time = kwargs.delete(:time) or Time.now
          TimeScheduler.add(time, event, channel, **kwargs)
        else
          channel.fire(event, **kwargs)
        end
      end
    nil end
    
    def fire_and_wait(*args, **kwargs)
      kwargs[:blocking]=true
      fire(*args, **kwargs)
    end
    
  end

end