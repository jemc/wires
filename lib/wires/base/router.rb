
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
      
      def clear
        initialize
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
      def self.new(&block)
        obj = super
        obj.singleton_class.class_eval &block
        obj
      end
      
      def initialize
        @table = Hash.new { |h,k| h[k] = Router::Map.new }
      end
    end
    
    Default = Abstract.new do
      def clear_channels()
        @table[:main].clear
        @table[:fuzzy].clear
        
        @star = Channel['*'.freeze]
      end
      
      def forget_channel(chan_cls, name)
        @table[:main].delete name
        @table[:fuzzy].delete name
      end
      
      def get_channel(chan_cls, name)
        return @star if @star and name == '*'
        
        channel = @table[:main][name]
        return channel if channel
        @table[:main][name] = channel = yield name
        
        if name.is_a? Regexp
          @table[:fuzzy][name] = channel
          channel.not_firable = [TypeError,
            "Cannot fire on Regexp channel: #{name.inspect}."\
            "  Regexp channels can only used in event handlers."]
        end
        
        channel
      end
      
      def get_receivers(chan)
        name = chan.name
        return @table[:main].values if name == '*'
        
        @table[:fuzzy].each_pair.select do |k,v|
          (begin; name =~ k; rescue TypeError; end)
        end.map { |k,v| v } + [chan, @star]
      end
    end
    
    Simple = Abstract.new do
      def clear_channels
        @table[:main].clear
      end
      
      def forget_channel(chan_cls, name)
        @table[:main].delete name
      end
      
      def get_channel(chan_cls, name)
        @table[:main][name] ||= yield name
      end
      
      def get_receivers(chan)
        [chan]
      end
    end
    
  end
end
