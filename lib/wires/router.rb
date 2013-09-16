
module Wires
  
  class Router
    
    @table = Hash.new
    
    class << self
      
      attr_accessor :table
      
      def clear_channels()
        @initialized = true
        @table       = {}
        @fuzzy_table = {}
        Channel['*']
      end
      
      def get_channel(chan_cls, name)
        channel = @table[name] ||= (new_one=true; yield name)
        
        if new_one and name.is_a? Regexp then
          @fuzzy_table[name] = channel
          channel.not_firable = [TypeError,
            "Cannot fire on Regexp channel: #{name.inspect}."\
            "  Regexp channels can only used in event handlers."]
        end
        
        channel
      end
      
      def get_receivers(chan)
        name = chan.name
        @fuzzy_table.keys.select do |k|
          (begin; name =~ k; rescue TypeError; end)
        end.map { |k| @fuzzy_table[k] } << chan
      end
      
    end
  end
  
end
