
# Store a list of all Event classes that get loaded.
class EventRegistry
    @@registry = []
    
    def self.<<(cls)
        @@registry << cls
        @@registry.uniq!
    end
    
    def self.list
        @@registry
    end
end

# All Event classes should inherit from this one
class Event
    
    # Register with the EventRegistry and make subclasses do the same
    EventRegistry << self
    def self.inherited(subcls)
        
        # Be sure codestring doesn't conflict
        existing = self._from_codestring(subcls.codestring)
        if existing then raise NameError, \
                "New Event subclass '#{subcls}' conflicts with"\
                " existing Event subclass '#{existing}'."\
                " The generated codestring '#{subcls.codestring}'"\
                " must be unique for each Event subclass." end
        
        # Register, then call super
        EventRegistry << subcls
        super
    end
    
    # List of class inheritance lineage back to but excluding Object
    def self.ancestry(cls=self)
        _next = cls.superclass
        [cls==Object ? [] : [cls, self.ancestry(_next)]].flatten
    end
    
    # Convert class <ClassNameEvent> to string "class_name"
    def self.codestring(cls=self)
        cls.to_s
           .underscore
           .gsub(/_event$/, "")
    end
    
    # List of codestrings associated with this event and ancestors
    def self.codestrings
        x = self.ancestry
                .map {|cls| cls.codestring}
    end
    
    # Pull class from registry by codestring 
    # (more reliable than crafting a reverse regexp)
    def self._from_codestring(str)
        return EventRegistry.list
                            .select{|e| e.codestring==str}[0]
    end
    def self.from_codestring(str)
        cls = self._from_codestring(str)
        if not cls then raise NameError,
            "No known Event subclass with codestring: '#{str}'" end
        cls
    end
    
    # Create attributes and accessors for all arguments to the constructor.
    # This is done here rather than in initialize so that the functionality
    # will remain if the user developer overrides initialize in the subclass.
    def self.new(*args, &block)
        obj = super
        
        kwargs = args[-1].is_a?(Hash) ? args.pop : Hash.new
        kwargs[:args] = args
        kwargs[:proc] = block if block
        for key in kwargs.keys
            att = key.to_s
            obj.instance_variable_set("@#{att}", kwargs[key])
            self.class_eval("def #{att}; @#{att}; end")
            self.class_eval("def #{att}=(val); @#{att}=val; end")
        end
        
        obj
    end
    
    # Calling super in self.new with *args will complain if this isn't here
    def initialize(*args, &block) end
end


#
# Comparison support for Events and Symbols/Strings
#

# Reopen Event and add comparison functions
class Event
    def self.==(other)
        other.is_a?(Class) ? 
            super : self.codestring==other.to_s
    end
    def self.<=(other)
        other.is_a?(Class) ? 
            super : self.codestrings.include?(other.to_s)
    end
    def self.<(other)
        other.is_a?(Class) ? 
            super : (self<=other and not self==other)
    end
    def self.>=(other)
        other.is_a?(Class) ? 
            super : Event.from_codestring(other.to_s)<=self
    end
    def self.>(other)
        other.is_a?(Class) ? 
            super : Event.from_codestring(other.to_s)<self
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