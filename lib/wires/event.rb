
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
      
      @kwargs.keys.each do |m|
        if respond_to? m
          (class << self; self; end).class_eval do
            undef_method m
          end
        end
      end
      
      (@kwargs[:args] = args.freeze; @ignore<<:args) \
        unless @kwargs.has_key? :args
      (@kwargs[:codeblock] = block; @ignore<<:codeblock) \
        unless @kwargs.has_key? :codeblock
      @kwargs.freeze
    end
    
    # Directly access contents of @kwargs by key
    def [](key); @kwargs[key]; end
    
    # Used to fake a sort of read-only openstruct from contents of @kwargs
    def method_missing(sym, *args, &block)
      args.empty? and @kwargs.has_key?(sym) ?
        @kwargs[sym] :
        (sym==:kwargs ? @kwargs.reject{|k| @ignore.include? k} : super)
    end
    
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
