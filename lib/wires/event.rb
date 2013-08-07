
module Wires
  
  class Event
    class << self
      def event_registry_create
        @@registry = []
        event_registry_register
      end
      def event_registry_register(cls=self)
        @@registry << cls
        @@registry.uniq!
      end
    end
    event_registry_create
  end
  
  # All Event classes should inherit from this one
  class Event
    
    # Operate on the metaclass as a type of singleton pattern
    class << self
      
      def inherited(subcls)
        # Be sure codestring doesn't conflict
        existing = _from_codestring(subcls.codestring)
        if existing then raise NameError, \
          "New Event subclass '#{subcls}' conflicts with"\
          " existing Event subclass '#{existing}'."\
          " The generated codestring '#{subcls.codestring}'"\
          " must be unique for each Event subclass." end
        
        super
        event_registry_register(subcls)
      end
      
      # List of class inheritance lineage back to but excluding Object
      def ancestry(cls=self)
        _next = cls.superclass
        [cls==Object ? [] : [cls, ancestry(_next)]].flatten
      end
      
      # Convert class <ClassNameEvent> to string "class_name"
      def codestring(cls=self)
        File.basename cls.to_s
        .underscore
        .gsub(/_event$/, "")
      end
      
      # List of codestrings associated with this event and ancestors
      def codestrings
        x = ancestry
        .map {|cls| cls.codestring}
      end
      
      # Pull class from registry by codestring 
      # (more reliable than crafting a reverse regexp)
      def _from_codestring(str)
        return @@registry.select{|e| e.codestring==str}[0]
      end; private :_from_codestring
      
      def from_codestring(str)
        cls = _from_codestring(str.to_s)
        if not cls then raise NameError,
          "No known Event subclass with codestring: '#{str}'" end
          cls
        end
      
      # Convert an event from 'array notation' to an Event subclass instance
      # TODO: List acceptable input forms here for documentation
      def new_from(input)
        
        # Standardize to array and pull out arguments if they exist
        input = [input] unless input.is_a? Array
        input, *args = input
        
        # Create event object from event as an object, class, or symbol/string
        event = case input
          when Event
            input
          when Class
            input.new(*args) if input < Event
          else
            Event.from_codestring(input.to_s).new(*args)
        end
      end
      
      # Create attributes and accessors for all arguments to the constructor.
      # This is done here rather than in initialize so that the functionality
      # will remain if the user developer overrides initialize in the subclass.
      def new(*args, &block)
        obj = super
        
        kwargs = args[-1].is_a?(Hash) ? args.pop.dup : Hash.new
        kwargs[:kwargs] = kwargs.dup.freeze
        kwargs[:args]   =   args.dup.freeze
        kwargs[:codeblock] = block if block
        for key in kwargs.keys
          att = key.to_s
          obj.instance_variable_set("@#{att}", kwargs[key])
          class_eval("def #{att}; @#{att}; end")
          # class_eval("def #{att}=(val); @#{att}=val; end")
        end
        
        obj
      end
    
    end
    
    # Calling super in new with *args will complain if this isn't here
    def initialize(*args, &block) end
    
  end
  
  #
  # Comparison support for Events and Symbols/Strings
  #
  
  # Reopen Event and add comparison functions
  class Event
    
    def =~(other)
      (self.class >= other.class) \
      and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
      and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})
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