
module Wires

  module Convenience
    
    # @original_instance_methods = 
    
    def on(events, channels='*', &codeblock)
      channels = [channels] unless channels.is_a? Array
      for channel in channels
        Channel.new(channel).register(events, codeblock)
      end
    nil end
    
    def fire(event, channel='*')
      Channel.new(channel).fire(event, blocking:false)
    nil end
    
    def fire_and_wait(event, channel='*') 
      Channel.new(channel).fire(event, blocking:true)
    nil end
    
    # def fire_every(interval, event, channel='*', **kwargs)
    #   Wires::TimeScheduler << \
    #     Wires::TimeSchedulerItem.new(self, event, channel, **kwargs)
    # end
    
    def Channel(*args) Channel.new(*args) end
    
    
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