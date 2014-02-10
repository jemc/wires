
module Wires.current_network::Namespace
  
  class RouterTable
    
    class AbstractReference
      attr_reader :ref
      def object; @ref.object; end
      def weak?; @weak end
      
      def initialize(obj)
        raise ValueError "AbstractReference referent cannot be nil" if obj.nil?
        
        # Make initial weak reference (if possible)
        begin
          @ref = Ref::WeakReference.new obj
          @weak = true
        rescue RuntimeError;
          @ref = Ref::StrongReference.new obj
          @weak = false
        end
      end
      
      def make_weak
        unless @weak
          @ref = Ref::WeakReference.new @ref.object
          @weak = true
        end
      rescue RuntimeError
      end
      
      def make_strong
        if @weak
          @ref = Ref::StrongReference.new @ref.object
          @weak = false
        end
      end
    end
    
    # A key reference is an AbstractReference that is 'transparent'
    # as a hash key.  That is - it acts as if the referenced object is the key
    class KeyReference < AbstractReference
      def hash
        object.hash
      end
      
      def eql?(other)
        hash == other.hash
      end
    end
    
    
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
