
module Wires.current_network::Namespace
  class Channel; end
  
  class Router
    
    class Category
      def initialize(name)
        @name = name
        @table = RouterTable.new
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
    
    attr_accessor :refreshes
    def refresh(&block) @refreshes << block unless block.nil? end
    
    def initialize(&block)
      @refreshes = []
      
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
    
    def clear_channels
      @categories.map(&:last).each { |c| c.table.clear }
      @refreshes.each { |r| instance_eval &r }
    end
    
    def get_channel(name, &block)
      channel = nil
      @categories.map(&:last).each do |c|
        if c.qualifiers.map { |q| instance_exec name, &q }.all?
          channel = (c.table[name] ||= (channel or yield name))
          c.executions.each { |e| instance_exec channel, &e }
          return channel if c.exclusive
        end
      end
      channel
    end
    
    def get_receivers(chan)
      [chan]
    end
    
    def forget_channel(name)
      @categories.map(&:last).each { |c| c.table.delete name }
    end
    
    def hold_channel(name)
      @categories.map(&:last).each { |c| c.table.make_strong name }
    end
    
    def release_channel(name)
      @categories.map(&:last).each { |c| c.table.make_weak name }
    end
    
    
    Simple = Router.new
    
    Default = Router.new do |r|
      r.category :star do |c|
        c.qualify { |name| @star and name == '*' }
        c.execute { |chan| @star = chan }
      end
      r.category :fuzzy do |c|
        c.exclusive = false
        c.qualify { |name| name.is_a? Regexp }
        c.execute { |chan| chan.not_firable = [TypeError,
              "Cannot fire on Regexp channel: #{chan.name.inspect}."\
              "  Regexp channels can only used in event handlers."] }
      end
      r.category :main
      
      r.refresh { @star = Channel['*'.freeze] }
      
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
