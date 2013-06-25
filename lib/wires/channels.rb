
def on(events, channels='*', &codeblock)
    channels = [channels] unless channels.is_a? Array
    for channel in channels
        Channel(channel).register(events, codeblock)
    end
nil end


def fire(event, channel='*') 
    Channel(channel).fire(event)
nil end


def Channel(*args) Channel.new(*args) end

class Channel
    
    attr_reader :name
    attr_reader :target_list
    
    def initialize(name)
        @name = name
        @target_list = Set.new
        @@channel_list << self
    nil end
    
    # Ensure that there is only one instance of Channel per name
    @@channel_list = Set.new
    @@new_lock = Mutex.new
    def self.new(*args, &block)
        @@new_lock.synchronize do
            (@@channel_list.select {|x|
                (x.name==args[0] and x.name.class==args[0].class)} [0]) \
            or super(*args, &block)
        end
    end
    
    # Class-wide reference to the global channel and event hub
    @@channel_star = Channel('*')
    @@hub = Hub.new
    
    # Register a proc to be triggered by an event on this channel
    def register(events, proc)
        
        if not proc.is_a?(Proc) then raise SyntaxError, \
            "No Proc given to execute on event: #{events}" end
        
        # Convert all events to strings
        events = [events] unless events.is_a? Array
        events.flatten!
        events.map! { |e| (e.is_a?(Class) ? e.codestring : e.to_s) }
        events.uniq!
        
        @target_list << [events, proc]
    nil end
    
    # Fire an event on this channel
    def fire(_event)
        
        # Pull out args from optional array notation
        _event = [_event] unless _event.is_a? Array
        _event, *args = _event
        
        # Create event object from event as an object, class, or symbol/string
        event = 
        case _event
            when Event
                _event
            when Class
                _event.new(*args) if _event < Event
            else
                cls = Event.from_codestring(_event.to_s).new(*args)
        end
        
        # Fire to each relevant target on each channel
        for chan in relevant_channels()
            for target in chan.target_list
                for string in target[0] & event.class.codestrings
                    @@hub.enqueue([string, event, *target[1..-1]])
        end end end
        
    nil end
    
    def relevant_channels
        return @@channel_list if self==@@channel_star
        
        if self.name.is_a?(Regexp) then raise TypeError,
            "Cannot fire on Regexp channel: #{self.name}."\
            "  Regexp channels can only used in event handlers." end
            
        relevant = [@@channel_star, self]
        for c in @@channel_list
            for code in Event.from_codestring(self.name).codestrings
                relevant << c if case c.name
                when Regexp
                    code =~ c.name
                when Event
                    code == c.name.class
                when Class
                    c.name <= Event ? 
                        code == c.name : 
                        code == c.name.to_s
                else
                    code == c.name.to_s
                end
            end
        end
        return relevant.uniq
    end
end