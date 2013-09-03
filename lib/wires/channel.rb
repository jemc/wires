
module Wires
  
  class Channel
    
    attr_reader :name
    attr_reader :target_list
    attr_reader :relevant_channels
    
    def inspect; "Channel(#{name.inspect})"; end
    
    # Redefine this class method to use an alternate Hub
    def self.hub; Hub; end
    # Don't redefine this instance method!
    def hub; self.class.hub; end
    
    # Give out references to the star channel
    def self.channel_star; @@channel_star; end
    def      channel_star; @@channel_star; end
    
    # Ensure that there is only one instance of Channel per name
    @@new_lock = Mutex.new
    def self.new(*args, &block)
      (args.include? :recursion_guard) ?
        (args.delete :recursion_guard) :
        (@@channel_star ||= self.new('*', :recursion_guard))
      
      @@new_lock.synchronize do
        @@channel_hash ||= Hash.new
        @@channel_hash[args[0]] ||= super(*args, &block)
      end
    end
    
    def initialize(name)
      @name = name
      @target_list = Set.new
      unless @@channel_hash.empty?
        _relevant_init
        @@channel_hash.values.each do |c| 
          c.send(:_test_relevance, self)
          _test_relevance c
        end
      else
        @relevant_channels = []
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
      proc
    end
    
    # Register hook to execute before fire - can call multiple times
    def self.before_fire(retain=false, &block)
      @before_fires ||= []
      @before_fires << [block, retain]
    nil end
    
    # Register hook to execute after fire - can call multiple times
    def self.after_fire(retain=false, &block)
      @after_fires ||= []
      @after_fires << [block, retain]
    nil end
    
    def self.run_hooks(hooks_sym, *exc_args)
      hooks = self.instance_variable_get(hooks_sym.to_sym)
      for hook in hooks
        proc, retain = hook
        proc.call(*exc_args)
      end if hooks
    nil end
    
    def self.clear_hooks(hooks_sym, force=false)
      hooks = self.instance_variable_get(hooks_sym.to_sym)
      self.instance_variable_set(hooks_sym.to_sym,
        (force ? [] : hooks.select{|h| h[1]})) if hooks
    nil end
    
    # Fire an event on this channel
    def fire(event, blocking:false)
      
      raise *@not_firable if @not_firable
      
      backtrace = caller
      
      # Create an instance object from one of several acceptable input forms
      event = Event.new_from event
      
      self.class.run_hooks(:@before_fires, event, self)
      
      # Fire to each relevant target on each channel
      for chan in relevant_channels()
        for target in chan.target_list
          for string in target[0] & event.class.codestrings
            self.class.hub.spawn(event,     # fired event object event
                                 self.name, # name of channel fired from
                                 target[1], # proc to execute
                                 blocking,  # boolean from blocking kwarg
                                 backtrace) # captured backtrace
      end end end
      
      self.class.run_hooks(:@after_fires, event, self)
      
    nil end
    
    def _relevant_init
      @relevant_channels = [@@channel_star]
      @my_names = (self.name.is_a? Array) ? self.name : [self.name]
      @my_names.map {|o| (o.respond_to? :channel_name) ? o.channel_name : o.to_s}
              .flatten(1)
      _test_relevance self
    end
    
    def _test_relevance(other_chan)
      if self==@@channel_star
        @relevant_channels << other_chan
        return
      end
      
      for my_name in @my_names
        
        if my_name.is_a?(Regexp) then 
          @not_firable = [TypeError,
          "Cannot fire on Regexp channel: #{self.name}."\
          "  Regexp channels can only used in event handlers."]
          return
        end
        
        other_name = other_chan.name
        other_name = (other_name.respond_to? :channel_name) ? \
                        other_name.channel_name : other_name
        
        @relevant_channels << other_chan if \
          !@relevant_channels.include?(other_chan) and \
          if other_name.is_a?(Regexp)
            my_name =~ other_name
          else
            my_name.to_s == other_name.to_s
          end
      end
    end
    
    # Compare matching with another Channel
    def =~(other)
      (other.is_a? Channel) ? (other.relevant_channels.include? self) : super
    end
    
    hub.before_kill(true) do
      self.clear_hooks(:@before_fires)
      self.clear_hooks(:@after_fires)
    end
    
  end
  
end