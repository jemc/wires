
module Wires.current_network::Namespace
  
  class RouterTable
    
    class Reference
      attr_reader :ref
      def object; @ref.object; end
      def weak?; @weak end
      
      def initialize(obj)
        raise ValueError "#{self.class} referent cannot be nil" if obj.nil?
        
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
      
      def inspect
        "<##{self.class} #{object.nil? ? "#Object not available" : object.inspect}>"
      end
    end
    
  end
  
  
  class RouterTable
    include Enumerable
    
    def initialize
      @keys = {}
      @key_ids = {}
      @values = {}
      @lock = Mutex.new
      @finalizer = lambda { |id| remove_reference_to_key id }
    end
    
    def [](key)
      @lock.synchronize do
        ref = @values[@key_ids[key.hash]]
        ref.object if ref
      end
    end
    
    def []=(key, value)
      begin; ObjectSpace.define_finalizer key, @finalizer
      rescue RuntimeError; end
      
      @lock.synchronize do
        id    = key.object_id
        key   = RouterTable::Reference.new key
        value = RouterTable::Reference.new value
        
        @keys[id] = key
        @values[id] = value
        @key_ids[key.object.hash] = id
      end
    end
    
    def delete(key)
      @lock.synchronize do
        id = @key_ids[key.hash]
        @key_ids.delete key.hash
        @keys.delete id
        @values.delete id
      end
    end
    
    def clear
      @lock.synchronize do
        @keys.clear
        @values.clear
        @key_ids.clear
      end
      nil
    end
    
    def keys;     @keys.values.map(&:object) end
    def values; @values.values.map(&:object) end
    
    def each
      Enumerator.new do |y|
        @key_ids.values.each do |id|
          key = @keys[id]
          val = @values[id]
          y << [key.object,val.object] unless key.nil? or val.nil?
        end
      end.each
    end
    alias_method :each_pair, :each
    
    def make_weak(key)
      @lock.synchronize do
        id = @key_ids[key.hash]
        @keys[id].make_weak
        @values[id].make_weak
      end
    end
    
    def make_strong(key)
      @lock.synchronize do
        id = @key_ids[key.hash]
        @keys[id].make_strong
        @values[id].make_strong
      end
    end
    
  private
    
    def remove_reference_to_key(object_id)
      @lock.synchronize do
        @key_ids.delete_if { |k,v| v==object_id }
        @keys.delete object_id
        @values.delete object_id
      end
    end
  end
  
end
