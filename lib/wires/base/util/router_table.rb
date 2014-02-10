
module Wires.current_network::Namespace
  
  class RouterTable
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
  
end
