
module Wires.current_network::Namespace
  
  class Event
    attr_accessor :type
    attr_accessor :kwargs
    attr_accessor :args
    attr_accessor :codeblock
    
    # Return a friendly output upon inspection
    def inspect
      list = kwargs.empty? ? [*args] : [*args, **kwargs]
      list << codeblock.to_s if codeblock
      list = list.map(&:inspect).join ', '
      the_type = type ? type.inspect : ''
      "#{the_type}[#{list}]"
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
    
    # Convert to a Wires::Event; returns self, unaltered
    def to_wires_event; self; end
    
    # Directly access contents of @kwargs by key
    def [](key); @kwargs[key]; end
    
    # Duplicate this event, ensuring that the args Array and kwargs Hash are
    #   not the same object, and receivers of an event can't modify that
    #   Array or Hash in ways that might affect other receivers of the event
    def dup
      Event.new *@args, type:@type, **@kwargs, &@codeblock
    end
    
    # Returns true if all meaningful components of two events are equal
    # Use #equal? instead if you want object identity comparison
    def ==(other)
      (other = other.to_wires_event if other.respond_to? :to_wires_event) ? 
        ((self.type      == other.type)   and
         (self.args      == other.args)   and
         (self.kwargs    == other.kwargs) and
         (self.codeblock == other.codeblock)) :
        super
    end
    
    # Returns true if listening for 'self' would hear a firing of 'other'
    # (not commutative)
    def =~(other)
      (other = other.to_wires_event if other.respond_to? :to_wires_event) ? 
        (([:*, other.type].include? self.type) and 
         (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) and
         (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
    
    # Return an array of Event instance objects from the input
    def self.list_from(*args)
      args.flatten.map &:to_wires_event
    end
    
  end
  
end
