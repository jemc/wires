
module Wires
  
  class ChannelKeeper
    
    @table = Hash.new
    
    class << self
      
      attr_accessor :table
      
      def clear_channels()
        @initialized = true
        @table       = {}
        @fuzzy_table = {}
        Channel['*']
      end
      
      def get_channel(chan_cls, name)
        channel = @table[name] ||= (new_one=true; yield name)
        
        if new_one and name.is_a? Regexp then
          @fuzzy_table[name] = channel
          channel.not_firable = [TypeError,
            "Cannot fire on Regexp channel: #{name.inspect}."\
            "  Regexp channels can only used in event handlers."]
        end
        
        channel
      end
      
      def get_receivers(chan)
        name = chan.name
        @fuzzy_table.keys.select do |k|
          (begin; name =~ k; rescue TypeError; end)
        end.map { |k| @fuzzy_table[k] } << chan
      end
      
    end
  end
  
  class Channel
    
    attr_reader :name
    attr_reader :target_list
    attr_accessor :not_firable
    
    def inspect; "#{self.class}(#{name.inspect})"; end
    
    @hub    = Hub
    @router = ChannelKeeper
    @new_lock = Mutex.new
    
    class << self
      attr_accessor :hub
      attr_accessor :router
      
      def new(*args)
        channel = @new_lock.synchronize do
          router.get_channel(self, *args) do |name|
            super(name)
          end
        end
      end
      alias_method :[], :new
    end
    
    def initialize(name)
      @name = name
      @target_list = Set.new
    end
    
    # Register a proc to be triggered by an event on this channel
    # Return the proc that was passed in
    def register(*events, &proc)
      if not proc.is_a?(Proc) then raise SyntaxError, \
        "No Proc given to execute on event: #{events}" end
      events = [*Event.new_from(*events)]
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
      
      event = Event.new_from(input)
      raise ArgumentError, "Can't create an event from input: #{input.inspect}"\
        unless event
      
      raise ArgumentError, "Can't fire on multiple events: #{event.inspect}" \
        unless event.count == 1
      event = event.first
      
      self.class.run_hooks(:@before_fire, event, self)
      
      # Fire to each relevant target on each channel
      for chan in self.class.router.get_receivers self
        for target in chan.target_list
          for e in target.first
            if e =~ event
              self.class.hub.spawn(event,     # fired event object event
                                   self.name, # name of channel fired from
                                   target.last, # proc to execute
                                   blocking,  # boolean from blocking kwarg
                                   backtrace) # captured backtrace
      end end end end
      
      self.class.run_hooks(:@after_fire, event, self)
      
    nil end
    
    # Fire a blocking event on this channel
    def fire_and_wait(event)
      self.fire(event, blocking:true)
    end
    
    # Compare matching with another Channel
    def =~(other)
      (other.is_a? Channel) ? (other.relevant_channels.include? self) : super
    end
    
  end
  
  ChannelKeeper.clear_channels
  
end