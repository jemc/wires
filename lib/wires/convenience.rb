
module Wires

  module Convenience
    
    def Channel(*args) Channel.new(*args) end
    
    def on(events, channels='*', &codeblock)
      channels = [channels] unless channels.is_a? Array
      for channel in channels
        channel=Channel.new(channel) unless channel.is_a? Channel
        channel.register(events, codeblock)
      end
    nil end
    
    def fire(event, channel='*', **kwargs)
      channel = Channel.new(channel) unless channel.is_a? Channel
      unless kwargs[:time] or (kwargs[:count] and kwargs[:count]!=1)
        channel.fire(event, **kwargs)
      else
        time = kwargs[:time] or Time.now
        kwargs.reject!{|k,v| k==:time}
        TimeScheduler.add(time, event, channel, **kwargs)
      end
    nil end
    
    def fire_and_wait(*args, **kwargs)
      kwargs[:blocking]=true
      fire(*args, **kwargs)
    end
    
    
    
    class << self
      def prefix_methods(prefix)
        
        return unless prefix
        prefix = prefix.to_s
        
        instance_methods.each do |thing|
          thing = thing.to_s
          f2 = (prefix+'_'+thing)
          f2 = (thing[0]=~/[[:lower:]]/) ? f2.underscore : f2.camelcase
          f2 = f2.to_sym; thing = thing.to_sym
          alias_method f2, thing
          remove_method thing
        end
        
        # remove_method :prefix_methods
        
      end
    end
    
  end

end