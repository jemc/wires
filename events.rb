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
        existing = self.from_codestring(subcls.codestring)
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
           .gsub(/(?<!(?:_|^))([A-Z])/, "_\\1")
           .downcase
           .gsub(/_event/, "")
    end
    
    # List of codestrings associated with this event and ancestors
    def self.codestrings
        x = self.ancestry
                .map {|cls| cls.codestring}
    end
    
    # Pull class from registry by codestring 
    # (more reliable than crafting a reverse regexp)
    def self.from_codestring(str)
        return EventRegistry.list
                            .select{|e| e.codestring==str}[0]
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
