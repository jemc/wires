
module Wires
  
  class Event
    attr_accessor :event_type
    
    # Return a friendly output upon inspection
    def inspect
      list = [*args, **kwargs].map(&:inspect).join ', '
      type = event_type ? event_type.inspect : ''
      "#{self.class}#{type}(#{list})"
    end
    
    # Internalize all *args and **kwargs and &block to be accessed later
    def initialize(*args, **kwargs, &block)
      cls = self.class
      self.event_type = cls unless cls==Wires::Event
      
      @ignore = []
      @kwargs = kwargs.dup
      
      (@kwargs[:args] = args.freeze; @ignore<<:args) \
        unless @kwargs.has_key? :args
      (@kwargs[:codeblock] = block; @ignore<<:codeblock) \
        unless @kwargs.has_key? :codeblock
      @kwargs.freeze
      
      @kwargs.keys.each do |m|
        singleton_class.send(:define_method, m) { @kwargs[m] }
      end
      singleton_class.send(:define_method, :kwargs) { 
        @kwargs.reject{|k| @ignore.include? k}
      }
    end
    
    # Directly access contents of @kwargs by key
    def [](key); @kwargs[key]; end
    
    # Returns true if listening for 'self' would hear a firing of 'other'
    # (not commutative)
    def =~(other)
      (other.is_a? Event) ? 
        ((self.class >= other.class) \
          and (self.event_type.nil? or self.event_type==other.event_type \
              or (self.event_type.is_a? Class and other.event_type.is_a? Class \
                  and self.event_type >= other.event_type)) \
          and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
          and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
    
    # Return an array of Event instance objects generated from
    # specially formatted input (see spec/event_spec.rb).
    def self.new_from(*args)
      args.flatten!
      list = []
      
      args.each do |x|
        (x.is_a? Hash) ? 
          (x.each_pair { |x,y| list << [x,y] }) :
          (list << [x,[]])
      end
      
      list.map! do |type, args|
        case type
        when Event; obj = type
        when Class; 
          if type<=Event 
            obj = type.new(*args)
          end
        when Symbol
          obj = self.new(*args)
          obj.event_type = type
          obj if self==Wires::Event
        end
        obj
      end.tap do |x|
        raise ArgumentError, 
        "Invalid event creation input: #{args} \noutput: #{x}" \
          if x.empty? or !x.all?
      end
    end
    
    # Ensure that self.new_from is not inherited
    def self.inherited(subcls)
      super
      class << subcls
        undef_method :new_from
      end if self == Wires::Event
    end
    
  end
  
end
