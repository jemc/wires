
module Wires
  
  class Event
    attr_accessor :event_type
    
    def self.new_from(input)
      return nil unless (input.is_a? Hash and input.keys.count==1)
      type, args = *input.shift
      case type
      when Event; input
      when Class; (type<=Event) ? type.new(*args) : nil
      when Symbol
        obj = self.new(*args)
        obj.event_type = type
        obj
      end
    end
    
    def initialize(*args, **kwargs, &block)
      @ignore = []
      @kwargs = kwargs.dup
      (@kwargs[:args] = args.freeze; @ignore<<:args) unless @kwargs.key? :args
      (@kwargs[:codeblock] = block; @ignore<<:codeblock) if block
      @kwargs.freeze
    end
    
    def [](key); @kwargs[key]; end
    
    def method_missing(sym, *args, &block)
      args.empty? and @kwargs.has_key?(sym) ?
        @kwargs[sym] :
        (sym==:kwargs ? @kwargs.reject{|k| @ignore.include? k}.freeze : super)
    end
    
    # def =~(other)
    #   (other.is_a? Event) ? 
    #     ((self.class >= other.class) \
    #       and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
    #       and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
    #     super
    # end
  end
  
end