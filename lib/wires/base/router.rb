
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
      
      class Category
        attr_reader :table
        
        def initialize
          @table = Router::Map.new
        end
      end
      
      def initialize(&block)
        # @table = Hash.new { |h,k| h[k] = Router::Map.new }
        singleton_class.class_exec self, &block
      end
      
      def category sym
        @categories ||= {}
        @categories[sym] = Category.new
      end
      
      attr_accessor :name
      
      def clear_channels
        @categories.values.each { |c| c.table.clear }
      end
      
      def forget_channel(chan_cls, name)
        @categories.values.each { |c| c.table.delete name }
      end
      
      # def get_channel(chan_cls, name, &block)
      #   @table.each { |t| t[name] ||= yield name }
      # end
      
      # def get_receivers(chan)
      #   [chan]
      # end
    end
    
    Simple = Abstract.new do |r|
      r.category :main
      
      def get_channel(chan_cls, name, &block)
        @categories[:main].table[name] ||= block.call name
      end
      
      def get_receivers(chan)
        [chan]
      end
    end
    
    Default = Abstract.new do |r|
      r.category :main
      r.category :fuzzy
      
      def clear_channels
        super
        @star = Channel['*'.freeze]
      end
      
      def get_channel(chan_cls, name, &block)
        if @star and name == '*'
          @star
        elsif (channel = @categories[:main].table[name])
          channel
        else
          @categories[:main].table[name] = channel = block.call name
          
          if name.is_a? Regexp
            @categories[:fuzzy].table[name] = channel
            channel.not_firable = [TypeError,
              "Cannot fire on Regexp channel: #{name.inspect}."\
              "  Regexp channels can only used in event handlers."]
          end
          
          channel
        end
      end
      
      def get_receivers(chan)
        name = chan.name
        if name == '*'
          @categories[:main].table.values
        else
          @categories[:fuzzy].table.each_pair.select do |k,v|
            (begin; name =~ k; rescue TypeError; end)
          end.map { |k,v| v } + [chan, @star]
        end
      end
    end
    
  end
end
