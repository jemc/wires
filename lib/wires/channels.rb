
def on(events, channels='*', &codeblock)
  channels = [channels] unless channels.is_a? Array
  for channel in channels
    Channel(channel).register(events, codeblock)
  end
nil end


def fire(event, channel='*') 
  Channel(channel).fire(event, blocking:false)
nil end

def fire_and_wait(event, channel='*') 
  Channel(channel).fire(event, blocking:true)
nil end


def Channel(*args) Channel.new(*args) end

class Channel
  
  attr_reader :name
  attr_reader :target_list
  
  def initialize(name)
    @name = name
    @target_list = Set.new
  nil end
  
  # Ensure that there is only one instance of Channel per name
  @@channel_hash = Hash.new
  @@new_lock = Mutex.new
  def self.new(*args, &block)
    @@new_lock.synchronize do
      @@channel_hash[args[0]] ||= super(*args, &block)
    end
  end
  
  # Class-wide reference to the global channel and event hub
  @@channel_star = Channel('*')
  
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
          Hub << [string, event, blocking, *target[1..-1]]
    end end end
    
  nil end
  
  def relevant_channels
    return @@channel_hash.values if self==@@channel_star
    
    if self.name.is_a?(Regexp) then raise TypeError,
      "Cannot fire on Regexp channel: #{self.name}."\
      "  Regexp channels can only used in event handlers." end
      
    relevant = [@@channel_star]
    for c in @@channel_hash.values
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