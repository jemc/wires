
module Wires.current_network::Namespace
  module Router
    
    class Default
      class << self
        # Refuse to instantiate; it's a singleton!
        private :new
        
        def clear_channels()
          @table       = {}
          @fuzzy_table = {}
          @star        = nil
        end
        
        def forget_channel(chan_cls, name)
          @table.delete name
          @fuzzy_table.delete name
        end
        
        def get_channel(chan_cls, name)
          @chan_cls ||= chan_cls
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
          return @table.values if name == '*'
          
          @fuzzy_table.each_pair.select do |k,v|
            (begin; name =~ k; rescue TypeError; end)
          end.map { |k,v| v } + [chan, (@star||=@chan_cls['*'])]
        end
        
      end
      clear_channels
    end
    
    
    class Simple
      class << self
        # Refuse to instantiate; it's a singleton!
        private :new
        
        def clear_channels()
          @table = {}
        end
        
        def forget_channel(chan_cls, name)
          @table.delete name
        end
        
        def get_channel(chan_cls, name)
          @table[name] ||= yield name
        end
        
        def get_receivers(chan)
          [chan]
        end
        
      end
      clear_channels
    end
    
    
  end
end
