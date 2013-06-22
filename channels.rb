
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
    def register(event, proc)
        @target_list << [event, proc]
    end
    
    # Fire an event on this channel (and the global channel)
    def fire(event)
        @target_list
            .select{|x| x[0]==event}
            .each  {|x| @@hub.enqueue(x)}
        if @@channel_star != self
            @@channel_star.fire(event)
        end
    end
end