
module Wires
  
  class Event
    attr_accessor :event_type
    
    def self.new_from(*args)
      list = []
      
      args.each do |x|
        (x.is_a? Hash) ? 
          (x.each_pair { |x,y| list << [x,y] }) :
          (list << [x,[]])
      end
      
      list.map! do |type, args|
        case type
        when Event; type
        when Class; (type<=Event) ? type.new(*args) : nil
        when Symbol
          self.new(type, *args)
        end
      end.reject(&:nil?)
    end
    
    def initialize(type, *args, **kwargs, &block)
      @event_type = type
      
      @ignore = []
      @kwargs = kwargs.dup
      (@kwargs[:args] = args.freeze; @ignore<<:args) \
        unless @kwargs.key? :args
      (@kwargs[:codeblock] = block; @ignore<<:codeblock) \
        unless @kwargs.key? :codeblock
      @kwargs.freeze
    end
    
    def [](key); @kwargs[key]; end
    
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
          and (self.event_type.nil? or self.event_type == other.event_type) \
          and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
          and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
  end
  
end
