
module Wires
  
  class Channel
    
    attr_reader :name
    attr_reader :handlers
    attr_accessor :not_firable
    
    def inspect; "#{self.class}[#{name.inspect}]"; end
    
    @hub    = Hub
    @router = Router::Default
    @new_lock = Monitor.new
    @@aim_lock = Mutex.new
    
    # Add hook methods
    extend Util::Hooks
    
    class << self
      attr_accessor :hub
      attr_accessor :router
      
      def new(*args)
        channel = @new_lock.synchronize do
          router.get_channel(self, *args) { |name| super(name) }
        end
      end
      alias_method :[], :new
    end
    
    def initialize(name)
      @name = name
      @handlers = []
    end
    
    # Register a proc to be triggered by an event on this channel
    # Return the proc that was passed in
    def register(*events, &proc)
      raise ArgumentError, "No callable given to execute on event: #{events}" \
        unless proc.respond_to? :call
      events = Event.list_from *events
      
      @@aim_lock.synchronize do
        @handlers << [events, proc] \
          unless @handlers.include? [events, proc]
      end
      
      # Insert the @registered_channels variable into the proc
      channels = proc.instance_variable_get(:@registered_channels)
      if channels
        channels << self
      else
        proc.instance_variable_set(:@registered_channels, [self])
      end
      
      # Insert the #unregister method into the proc
      proc.singleton_class.send :define_method, :unregister do
        singleton_class.send :remove_method, :unregister
        @registered_channels.each do |c|
          c.unregister self
        end
      end unless proc.respond_to? :unregister
      
      proc
    end
    
    # Unregister a proc from the target list of this channel
    # Return true if at least one matching target was unregistered, else false
    def unregister(proc)
      @@aim_lock.synchronize do
        !!(@handlers.reject! do |stored_events, stored_proc|
          proc==stored_proc
        end)
      end
    end
    
    # Fire an event on this channel.
    #
    # Each handler with an event pattern matching the fired event (see 
    # {Event#=~}) that is {#register}ed on a channel that matches the firing 
    # channel (see {Channel#=~}) will be executed, and passed the event object
    # and channel name as arguments.
    #
    # This method fires in a nonblocking manner by default, but this behavior 
    # can be overriden with the +:blocking+ parameter. See {#fire!} for 
    # blocking default behavior.
    #
    # @param [Event, Symbol] input the event to be fired, as an Event or Symbol.
    #   In this context, a Symbol is treated as an 'empty' Event of that type
    #   (see to {Symbol#[]}).
    # @param [Boolean] :blocking when true, the method will wait to return 
    #   until all handlers have finished their execution.
    # @param [Boolean] :parallel when true, the handlers will be executed in 
    #   parallel, if there are more than one; otherwise, they will be executed
    #   serially (in an undefined order).  Unless otherwise specified, this 
    #   parameter will be set to the opposite of the value of the :blocking
    #   parameter; that is, nonblocking firing will by default also be parallel,
    #   and blocking firing will by default also be sequential.
    #
    # @return [Array<Thread>] the array of threads spawned by the method, 
    #   if any.  This could be useful for manually joining the threads later
    #   or monitoring their status.
    #
    # @raise An exception of the type and message contained in the 
    #   {#not_firable} attribute if it has been assigned by the active {Router} 
    #   through the {#not_firable=} accessor.
    #
    # @TODO Test the return array in each of the four concurrency cases
    #
    def fire(event, blocking: false, parallel: !blocking)
      raise *@not_firable if @not_firable
      
      return [] << Thread.new { fire(event, blocking:true, parallel:false) } \
        if !blocking and !parallel
      
      backtrace = caller
      
      event = event.to_wires_event
      
      self.class.run_hooks(:@before_fire, event, self.name)
      
      # Select appropriate targets
      procs = []
      @@aim_lock.synchronize do
        self.class.router
        .get_receivers(self).each do |chan|
          chan.handlers.each do |elist, pr|
            elist.each do |e|
              procs << pr if e =~ event
            end
          end
        end
      end
      
      # Fire to selected targets
      threads = procs.uniq.map do |pr|
        self.class.hub.spawn \
          event,     # fired event object event
          self.name, # name of channel fired from
          pr,        # proc to execute
          blocking,  # boolean from blocking kwarg
          parallel,  # boolean from parallel kwarg
          backtrace  # captured backtrace
      end.reject &:nil?
      
      threads.each &:join if blocking and parallel
      
      self.class.run_hooks(:@after_fire, event, self.name)
      
      threads
    end
    
    # Fire an event on this channel.
    #
    # Each handler with an event pattern matching the fired event (see 
    # {Event#=~}) that is {#register}ed on a channel that matches the firing 
    # channel (see {Channel#=~}) will be executed, and passed the event object
    # and channel name as arguments.
    #
    # This method fires in a blocking manner by default, but this behavior 
    # can be overriden with the +:blocking+ parameter. See {#fire!} for 
    # nonblocking default behavior.
    #
    # @param (see Channel#fire)
    # @return (see Channel#fire)
    # @raise (see Channel#fire)
    # @overload fire!(event, blocking: true, parallel: !blocking)
    #
    def fire!(*args, **kwargs)
      kwargs[:blocking] = true unless kwargs.has_key? :blocking
      fire(*args, **kwargs)
    end
    
    # Determine if one channel matches another.
    # 
    # In this context, a match indicates a receiver relationship.
    # That is, this method tests if +self+ is one of the {#receivers} of 
    # +other+. For a matching pair of channels, a {#fire}d event on the 
    # right-hand channel could be received by a relevant event handler on 
    # the left-hand channel. 
    #
    # Note that receiver relationships are entirely dictated by the selected
    # {.router}. Also note that the operation is not necessarily commutative.
    # That is, having +a =~ b+ does not guarantee that +b =~ a+.
    #
    # @param other [Channel] the channel to which +self+ should be compared.
    # @return [Boolean] +true+ if +self+ is one of +other+'s {#receivers};
    #   +false+ otherwise.
    #
    def =~(other)
      (other.is_a? Channel) ?
        (self.class.router.get_receivers(other).include? self) : 
        super
    end
    
    def receivers
      self.class.router.get_receivers self
    end
    
  end
  
end