
module Wires
  
  # All Event classes should inherit from this one
  class Event
      
    # def self.new_from(input)
      
    #   # Standardize to array and pull out arguments if they exist
    #   input = [input] unless input.is_a? Array
    #   input, *args = input
      
    #   # Create event object from event as an object, class, or symbol/string
    #   event = case input
    #     when Event
    #       input
    #     when Class
    #       input.new(*args) if input <= Event
    #     else
    #       Event.from_codestring(input.to_s).new(*args)
    #   end
    # end
    
    def initialize(*args, **kwargs, &block)
      @kwargs = kwargs.dup
      @kwargs[:args] = args unless @kwargs.key? :args
      @kwargs[:codeblock] = block if block
      @kwargs.freeze
    end
    
    def [](key); @kwargs[key]; end
    
    def method_missing(sym, *args, &block)
      args.empty? and @kwargs.has_key?(sym) ?
        @kwargs[sym] :
        (sym==:kwargs ? @kwargs.dup : super)
    end
    
  end
  
  #
  # Comparison support for Events and Symbols/Strings
  #
  
  # Reopen Event and add comparison functions
  class Event
    
    def =~(other)
      (other.is_a? Event) ? 
        ((self.class >= other.class) \
          and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
          and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
    
    class << self
      def ==(other)
        other.is_a?(Class) ? 
        super : codestring==other.to_s
      end
      def <=(other)
        other.is_a?(Class) ? 
        super : codestrings.include?(other.to_s)
      end
      def <(other)
        other.is_a?(Class) ? 
        super : (self<=other and not self==other)
      end
      def >=(other)
        other.is_a?(Class) ? 
        super : Event.from_codestring(other.to_s)<=self
      end
      def >(other)
        other.is_a?(Class) ? 
        super : Event.from_codestring(other.to_s)<self
      end
    end
  end
  
  # Autogenerate the inverse comparison functions for Symbol/String
  for cls in [Symbol, String]
    %w(== < > <= >=).zip(%w(== > < >= <=))
    .each do |ops|
      op, opinv = ops # unzip operator and inverse operator
      cls.class_eval(
        "def #{op}(other)\n"\
        "    (other.is_a?(Class) and other<=Event) ? \n"\
        "        (other#{opinv}self) : super\n"\
        "end\n")
    end
  end
end