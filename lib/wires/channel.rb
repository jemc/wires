
def on(events, channels='*', &codeblock)
  channels = [channels] unless channels.is_a? Array
  for channel in channels
    Wires::Channel.new(channel).register(events, codeblock)
  end
nil end


def fire(event, channel='*') 
  Wires::Channel.new(channel).fire(event, blocking:false)
nil end

def fire_and_wait(event, channel='*') 
  Wires::Channel.new(channel).fire(event, blocking:true)
nil end


def Channel(*args) Wires::Channel.new(*args) end

module Wires
  class Channel
    
    attr_reader :name
    attr_reader :target_list
    
    def initialize(name)
      @name = name
      @target_list = Set.new
    nil end
    
    
    # Redefine this class method to use an alternate Hub
    def self.hub; Hub; end
    # Don't redefine this instance method!
    def hub; self.class.hub; end
    
    # Channel registry hash and star channel reference are values
    # In this Hash with the key being the reference to the Hub
    @@channel_hash = Hash.new
    @@channel_star = Hash.new
    
    # Give out references to the star channel
    def self.channel_star; @@channel_star[self.hub]; end
    def      channel_star; @@channel_star[self.hub]; end
    
    # Ensure that there is only one instance of Channel per name
    @@new_lock = Mutex.new
    def self.new(*args, &block)
      @@channel_star[self.hub] ||= Channel.new('*') unless (args[0]=='*')
      @@new_lock.synchronize do
        @@channel_hash[self.hub] ||= Hash.new
        @@channel_hash[self.hub][args[0]] ||= super(*args, &block)
      end
    end
    
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
    def fire(event, blocking:false)
      
      # Create an instance object from one of several acceptable input forms
      event = Event.new_from event
      
      # Fire to each relevant target on each channel
      for chan in relevant_channels()
        for target in chan.target_list
          for string in target[0] & event.class.codestrings
            self.class.hub << [string, event, blocking, *target[1..-1]]
      end end end
      
    nil end
    
    def relevant_channels
      return @@channel_hash[hub].values if self==channel_star
      
      if self.name.is_a?(Regexp) then raise TypeError,
        "Cannot fire on Regexp channel: #{self.name}."\
        "  Regexp channels can only used in event handlers." end
        
      relevant = [channel_star]
      for c in @@channel_hash[hub].values
        relevant << c if \
          if c.name.is_a?(Regexp)
            self.name =~ c.name
          elsif (defined?(c.name.channel_name) and
               defined?(self.name.channel_name))
            self.name.channel_name == c.name.channel_name
          else
            self.name.to_s == c.name.to_s
          end
      end
      return relevant.uniq
    end
  end
end