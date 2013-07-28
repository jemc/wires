
WiresBuilder.define do |prefix|
  
code = <<CODE

  module Convenience
    
    def #{prefix}on(events, channels='*', &codeblock)
      channels = [channels] unless channels.is_a? Array
      for channel in channels
        parent[0]::Channel.new(channel).register(events, codeblock)
      end
    nil end
    
    def #{prefix}fire(event, channel='*') 
      parent[0]::Channel.new(channel).fire(event, blocking:false)
    nil end
    
    def #{prefix}fire_and_wait(event, channel='*') 
      parent[0]::Channel.new(channel).fire(event, blocking:true)
    nil end
    
    def #{prefix ? prefix.to_s.camelcase : nil}Channel(*args) parent[0]::Channel.new(*args) end

  end

CODE
  
  eval(code)
  
end


WiresBuilder.define do
  
  class self::Channel
    
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
      (args.include? :recursion_guard) ?
        (args.delete :recursion_guard) :
        (@@channel_star[self.hub] ||= self.new('*', :recursion_guard))
      
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
      backtrace = caller
      
      # Create an instance object from one of several acceptable input forms
      event = Event.new_from event
      
      # Fire to each relevant target on each channel
      for chan in relevant_channels()
        for target in chan.target_list
          for string in target[0] & event.class.codestrings
            self.class.hub.spawn(event, string, *target[1], blocking, backtrace)
      end end end
      
    nil end
    
    def relevant_channels
      return @@channel_hash[hub].values if self==channel_star
        
      relevant = [channel_star]
      my_names = (self.name.is_a? Array) ? self.name : [self.name]
      my_names.map {|o| (o.respond_to? :channel_name) ? o.channel_name : o.to_s}
              .flatten(1)
      
      for my_name in my_names
        
        if my_name.is_a?(Regexp) then raise TypeError,
          "Cannot fire on Regexp channel: #{self.name}."\
          "  Regexp channels can only used in event handlers." end
        
        for other_chan in @@channel_hash[hub].values
          
          other_name = other_chan.name
          other_name = (other_name.respond_to? :channel_name) ? \
                          other_name.channel_name : other_name
          
          relevant << other_chan if \
            if other_name.is_a?(Regexp)
              my_name =~ other_name
            else
              my_name.to_s == other_name.to_s
            end
            
        end
        
      end
      
      return relevant.uniq
    end
    
  end
  
end