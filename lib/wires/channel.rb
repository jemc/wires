
module Wires
  
  class ChannelKeeper
    
    @table    = Hash.new
    @new_lock = Mutex.new
    
    class << self
      
      attr_accessor :channel_star
      attr_accessor :table
      attr_accessor :new_lock
      
      def new_channel(chan_cls, *args, &block)
        @table['*'] ||= chan_cls.old_version_of_new('*')
        
        channel = @new_lock.synchronize do
          @table[args[0]] ||= chan_cls.old_version_of_new(*args, &block)
        end
        
        _relevant_init channel
        @table.values.each do |c|
          _test_relevance c, channel
          _test_relevance channel, c
        end
        
        channel
      end
      
      def _relevant_init(channel)
        channel.relevant_channels = [@table['*']]
        channel.my_names = (channel.name.is_a? Array) ? channel.name : [channel.name]
        channel.my_names.map {|o| (o.respond_to? :channel_name) ? o.channel_name : o.to_s}
                .flatten(1)
        _test_relevance channel, channel
      end
      
      def _test_relevance(chan, other_chan)
        if chan==@table['*']
          chan.relevant_channels << other_chan
          return
        end
        
        for my_name in chan.my_names
          
          if my_name.is_a?(Regexp) then 
            chan.not_firable = [TypeError,
            "Cannot fire on Regexp channel: #{chan.name}."\
            "  Regexp channels can only used in event handlers."]
            return
          end
          
          other_name = other_chan.name
          other_name = (other_name.respond_to? :channel_name) ? \
                          other_name.channel_name : other_name
          
          chan.relevant_channels << other_chan if \
            !chan.relevant_channels.include?(other_chan) and \
            if other_name.is_a?(Regexp)
              my_name =~ other_name
            else
              my_name.to_s == other_name.to_s
            end
        end
      end
      
    end
  end
  
  class Channel
    
    attr_reader :name
    attr_reader :target_list
    attr_accessor :relevant_channels
    attr_accessor :my_names
    attr_accessor :not_firable
    
    def inspect; "#{self.class}(#{name.inspect})"; end
    
    # Redefine this class method to use an alternate Hub
    def self.hub; Hub; end
    # Don't redefine this instance method!
    def hub; self.class.hub; end
    
    def router; self.class.router; end
    
    @router = ChannelKeeper
    
    class << self
      attr_accessor :router
      
      alias_method :old_version_of_new, :new
      def new(*args, &block)
        router.new_channel(self, *args, &block)
      end
      alias_method :[], :new
    end
    
    def initialize(name)
      @name = name
      @target_list = Set.new
      # router.init_channel(self)
    end
    
    # Register a proc to be triggered by an event on this channel
    # Return the proc that was passed in
    def register(*events, &proc)
      if not proc.is_a?(Proc) then raise SyntaxError, \
        "No Proc given to execute on event: #{events}" end
      _normalize_event_list(events)
      @target_list << [events, proc]
      proc
    end
    
    # Unregister a proc from the target list of this channel
    # Return true if at least one matching target was unregistered, else false
    def unregister(*events, &proc)
      _normalize_event_list(events)
      !!(@target_list.reject! do |e, p|
        (proc and proc==p) and (events.map{|event| e.include? event}.all?)
      end)
    end
    
    # Add hook methods
    class << self
      include Hooks
      
      def before_fire(*args, &proc)
        add_hook(:@before_fire, *args, &proc)
      end
      
      def after_fire(*args, &proc)
        add_hook(:@after_fire, *args, &proc)
      end
    end
    
    # Fire an event on this channel
    def fire(input, blocking:false)
      
      raise *@not_firable if @not_firable
      
      backtrace = caller
      
      # Create an instance object from one of several acceptable input forms
      event = Event.new_from input
      raise ArgumentError, "Can't create an event from input #{input.inspect}" \
        unless event
      
      self.class.run_hooks(:@before_fire, event, self)
      
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
      
      self.class.run_hooks(:@after_fire, event, self)
      
    nil end
    
    # Fire a blocking event on this channel
    def fire_and_wait(event)
      self.fire(event, blocking:true)
    end
    
    # Convert events to array of unique codestrings
    def _normalize_event_list(events)
      events = [events] unless events.is_a? Array
      events.flatten!
      events.map! { |e| (e.is_a?(Class) ? e.codestring : e.to_s) }
      events.uniq!
    end
    
    # Compare matching with another Channel
    def =~(other)
      (other.is_a? Channel) ? (other.relevant_channels.include? self) : super
    end
    
  end
  
end