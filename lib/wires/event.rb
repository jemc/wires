
module Wires
  
  class Event
    attr_accessor :type
    attr_accessor :kwargs
    attr_accessor :args
    attr_accessor :codeblock
    
    # Return a friendly output upon inspection
    def inspect
      list = [*args, **kwargs].map(&:inspect).join ', '
      the_type = type ? type.inspect : ''
      "#{self.class}#{the_type}:#{object_id}(#{list})"
    end
    
    # Internalize all *args and **kwargs and &block to be accessed later
    def initialize(*args, **kwargs, &block)
      if kwargs.has_key? :type
        @type = kwargs[:type]
        kwargs.delete  :type
      else
        @type = :*
      end
      
      @args      = args
      @kwargs    = kwargs
      @codeblock = block
      
      @kwargs.keys
        .reject{ |m| [:kwargs, :args, :codeblock].include? m }
        .each  { |m| singleton_class.send(:define_method, m) { @kwargs[m] } }
    end
    
    # Directly access contents of @kwargs by key
    def [](key); @kwargs[key]; end
    
    # Returns true if all meaningful components of two events are equal
    # Use #equal? instead if you want object identity comparison
    def ==(other)
      (other.is_a? Event) ? 
        ((self.type      == other.type)   and
         (self.args      == other.args)   and
         (self.kwargs    == other.kwargs) and
         (self.codeblock == other.codeblock)) :
        super
    end
    
    # Returns true if listening for 'self' would hear a firing of 'other'
    # (not commutative)
    def =~(other)
      (other.is_a? Event) ? 
        (([:*, other.type].include? self.type) and 
         (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) and
         (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
    
    # Return an array of Event instance objects generated from
    # specially formatted input (see spec/event_spec.rb).
    def self.new_from(*args)
      args.flatten.each_with_object([]) do |x, list|
        (x.is_a? Hash) ? 
          (x.each_pair { |x,y| list << [x,y] }) :
          (list << [x,[]])
      end.map do |the_type, obj_args|
        case the_type
        when Event;  the_type
        when Symbol; self.new(*obj_args).tap{|e| e.type=the_type}
        end
      end.tap do |x|
        raise ArgumentError, 
        "Invalid event creation input: #{args} \noutput: #{x}" \
          if x.empty? or !x.all?
      end
    end
    
  end
  
end
