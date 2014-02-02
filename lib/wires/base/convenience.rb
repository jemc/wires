
module Wires.current_network::Namespace

  module Convenience
    
    def on(events, channels=self, &codeblock)
      channels = [channels] unless channels.is_a? Array
      channels.each do |channel|
        channel=Channel.new(channel) unless channel.is_a? Channel
        
        channel.register(*events, &codeblock)
      end
      codeblock
    end
    
    def sync_on(event, channel=self, **kwargs, &codeblock)
      channel = Channel.new(channel) unless channel.is_a? Channel
      channel.sync_on(event, **kwargs, &codeblock)
    end
    
    def fire(event, channel=self, **kwargs)
      channel = Channel.new(channel) unless channel.is_a? Channel
      
      if kwargs[:time] or (kwargs[:count] and kwargs[:count]!=1)
        time = kwargs.delete(:time) or Time.now
        TimeScheduler.add(time, event, channel, **kwargs)
      else
        channel.fire(event, **kwargs)
      end
    nil end
    
    def fire!(*args, **kwargs)
      kwargs[:blocking] = true unless kwargs.has_key? :blocking
      fire(*args, **kwargs)
    end
    
  end

end