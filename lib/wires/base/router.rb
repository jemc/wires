
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
        def initialize(name)
          @name = name
          @table = Router::Map.new
          @exclusive = true
          @qualifiers = []
          @executions = []
          
          yield self if block_given?
        end
        
        attr_reader :name
        attr_reader :table
        attr_accessor :exclusive
        attr_accessor :qualifiers
        attr_accessor :executions
        
        def qualify(&block) @qualifiers << block unless block.nil? end
        def execute(&block) @executions << block unless block.nil? end
      end
      
      def initialize(&block)
        singleton_class.class_exec self, &block if block
        category :all unless @categories
      end
      
      def category sym, &block
        @categories ||= []
        @categories << [sym, Category.new(sym, &block)]
      end
      
      def table(key)
        Hash[@categories][key].table
      end
      
      attr_accessor :name
      
      def clear_channels
        @categories.map(&:last).each { |c| c.table.clear }
      end
      
      def forget_channel(name)
        @categories.map(&:last).each { |c| c.table.delete name }
      end
      
      def get_channel(name, &block)
        channel = nil
        @categories.map(&:last).each do |c|
          if c.qualifiers.map { |q| q.call name }.all?
            channel = (c.table[name] ||= (channel or yield name))
            c.executions.each { |e| e.call channel }
            return channel if c.exclusive
          end
        end
        channel
      end
      
      def get_receivers(chan)
        [chan]
      end
    end
    
    Simple = Abstract.new
    
    Default = Abstract.new do |r|
      r.category :fuzzy do |c|
        c.exclusive = false
        c.qualify { |name| name.is_a? Regexp }
        c.execute { |chan| chan.not_firable = [TypeError,
              "Cannot fire on Regexp channel: #{name.inspect}."\
              "  Regexp channels can only used in event handlers."] }
      end
      r.category :main
      
      def clear_channels
        super
        @star = Channel['*'.freeze]
      end
      
      def get_channel(name, &block)
        (@star and name == '*') ? @star : super
      end
      
      def get_receivers(chan)
        name = chan.name
        if name == '*'
          table(:main).values
        else
          table(:fuzzy).each_pair.select do |k,v|
            (begin; name =~ k; rescue TypeError; end)
          end.map { |k,v| v } + [chan, @star]
        end
      end
    end
    
  end
end
