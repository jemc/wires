
module Wires.current_network::Namespace
  class Channel; end
  
  module Router
    
    class Map
      include Enumerable
      
      def initialize
        @mainmap = {}
        @weakmap = Ref::WeakKeyMap.new
        @weakmap.extend Enumerable
      end
      
      def each(&block)
        Enumerator.new do |y|
          @mainmap.each { |e| y << e }
          @weakmap.each { |e| y << e }
        end.each(&block)
      end
      
      alias_method :each_pair, :each
      
      def keys;   map { |k,v| v } end
      def values; map { |k,v| v } end
      
      def [](key)
        @mainmap[key] or @weakmap[key]
      end
      
      def []=(key, value, weak:false)
        if weak and not key.frozen?
          @weakmap[key] = value
        else
          @mainmap[key] = value
        end
      end
      
      def delete(key)
        @mainmap.delete(key) or @weakmap.delete(key)
      end
    end
    
    class Abstract
      class << self
        # Refuse to instantiate; it's a singleton!
        private :new
      end
    end
    
    class Default < Abstract
      class << self
        
        def clear_channels()
          @table       = Router::Map.new
          @fuzzy_table = Router::Map.new
          @star        = Channel['*'.freeze]
        end
        
        def forget_channel(chan_cls, name)
          @table.delete name
          @fuzzy_table.delete name
        end
        
        def get_channel(chan_cls, name)
          return @star if @star and name == '*'
          
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
          end.map { |k,v| v } + [chan, @star]
        end
      end
    end
    
    class Simple < Abstract
      class << self
        def clear_channels()
          @table = Router::Map.new
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
    end
    
    
  end
end
