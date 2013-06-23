
def on(event, channel='*', &codeblock)
    Channel(channel).register(event, codeblock)
end


def fire(event, channel='*') 
    Channel(channel).fire(event)
end


def Channel(*args) Channel.new(*args) end

class Channel
    
    attr_reader :name
    attr_reader :target_list
    
    def initialize(name)
        @name = name
        @target_list = Set.new
        @@channel_list << self
    end
    
    # Ensure that there is only one instance of Channel per name
    @@channel_list = Set.new
    def self.new(*args, &block)
        (@@channel_list.select {|x| x.name == args[0]} [0]) \
        or super(*args, &block)
    end
    
    # Class-wide reference to the global channel and event hub
    @@channel_star = Channel('*')
    @@hub = Hub.new
    
    # Register a proc to be triggered by an event on this channel
    def register(events, proc)
        
        if not proc then raise SyntaxError, \
            "No Proc given to execute on event: #{events}" end
        
        # Convert all events to strings
        events = [events] unless events.is_a? Array
        events.flatten!
        events.map! { |e| (e.is_a?(Class) ? e.codestring : e.to_s) }
        events.uniq!
        
        
        @target_list << [events, proc]
    end
    
    # Fire an event on this channel (and the global channel)
    def fire(_event)
        
        event = (_event.is_a?(Event) ? 
            _event : 
            Event.from_codestring(_event.to_s))
        if not event
            raise NameError, "Cannot fire unknown event: #{_event}" end
        
        for target in @target_list
            for string in target[0] & event.codestrings
                @@hub.enqueue([string, event, *target[1..-1]])
            end
        end

        if @@channel_star != self
            @@channel_star.fire(event)
        end
    end
end