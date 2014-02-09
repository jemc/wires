
module Wires.current_network::Namespace
  
  #  
  #
  # = Hooks Summary
  # As a courtesy for custom services seeking to integrate with {Wires}, some
  # hooks are provided for the {Channel} class.  These hooks can be accessed
  # by the methods inherited from {Util::Hooks}.  Note that they are on a class
  # level, so registering a hook will affect all instances of {Channel}. 
  # There are two hooks types that {Channel} will invoke:
  # * +:@before_fire+ - yields the event object and channel {#name} to the 
  #   user block before {#fire} invokes {Hub.spawn} (see source code).
  # * +:@after_fire+ - yields the event object and channel {#name} to the 
  #   user block after {#fire} invokes {Hub.spawn} (see source code).
  class Channel
    
    # The unique name of the channel, which can be any kind of hashable object.
    #
    # Because it is unique, a reference to the channel may be obtained from 
    # the class-level method {Channel.[] Channel[]} using only the {#name}.
    #
    attr_reader :name
    
    # An array specifying the exception type and string to raise if {#fire} is
    # called, or +nil+ if it's okay to {#fire} from this channel.
    #
    # This is meant to be determined by the {Router} that is selected as the 
    # current {.router}, and not accessed from any other user code.
    #
    attr_accessor :not_firable
    
    # @return [String] friendly output showing the class and channel {#name}
    def inspect; "#{self.class}[#{name.inspect}]"; end
    
    @hub    = Hub
    @router = Router::Default
    @new_lock = Monitor.new
    @@aim_lock = Mutex.new # @api private
    
    extend Util::Hooks
    
    class << self
      
      # The currently selected {Hub} for all channels ({Hub} by default).
      #
      # It is the {Hub}'s responsibility to execute event handlers.
      # @api private
      #
      attr_accessor :hub
      
      # The currently selected {Router} for all channels 
      # ({Router::Default} by default).
      #
      # It is the router's responsibility to decide whether to create new 
      # channel objects or return existing ones when {.[] Channel[]} is called
      # and to determine which channels should receive {#fire}d events from
      # a channel (its {#receivers}).
      #
      # {Wires} provides two routers: {Router::Default} and {Router::Simple},
      # but any object that implements the router interface can be selected.
      #
      attr_accessor :router
      
      # Access a channel by {#name}, creating a new channel object if necessary.
      #
      # The work of deciding if an object with the given {#name} already 
      # exists is delegated to the currently selected {.router}.
      #
      # @note Because this method does not always create a new object,
      #   it is recommended to use the alias {[] Channel[]}, which more clearly
      #   communicates the intention.
      #
      # @param name [#hash] a hashable object of any type 
      #   to use as the channel {#name}
      #
      # @return [Channel] the new or existing channel object with that {#name}
      #
      def new(name)
        channel = @new_lock.synchronize do
          router.get_channel(self, name) { |name| super(name) }
        end
      end
      
      alias_method :[], :new
      
      # Forget a channel by {#name}.  All registered handlers are forgotten,
      # and a future attempt to access the channel object by name will create 
      # a new object.
      #
      # The work of forgetting the object with the given {#name} is delegated 
      # to the currently selected {.router}.
      #
      # @param name [#hash] a hashable object of any type as the channel {#name}
      #
      # @return [nil]
      #
      def forget(name)
        @new_lock.synchronize do
          router.forget_channel(self, name)
        end
        nil
      end
    end
    
    # Assigns the given +name+ as the {#name} of this channel object
    #
    # @param name [#hash] a hashable object of any type, unique to this channel
    #
    def initialize(name)
      @name = name
      @handlers = []
    end
    
    # Register an event handler to be executed when a matching event occurs.
    #
    # One or more event patterns should be passed as the arguments.
    # If an event matching one or more of the given event patterns is 
    # {#fire}d on a channel that has this channel as one of its {#receivers},
    # then the handler is executed, and yielded the event object and the {#name} 
    # of the channel upon which {#fire} was called as arguments.
    #
    # @param events [<Symbol, Event>] the event pattern(s)
    #   to listen for. If the pattern is a symbol or event with a type and no 
    #   other arguments, any event with that type will be heard.  If the 
    #   pattern is an event that has other arguments, each of the arguments 
    #   and keyword arguments in the pattern must also be present in the
    #   fired event for it to be heard by the handler, but the fired event may
    #   also include other arguments that were not declared in the pattern
    #   and still be heard by the handler (see {Event#=~}).
    # @param callable [Proc] the executable code to register as a handler 
    #   on this channel for the given pattern.
    #
    # @return [Proc] the +&callable+ given, which has been extended with an
    #   +#unregister+ method on the object itself. The injected method takes
    #   no arguments and will unregister the +&callable+ from every channel
    #   on which it is {#register}ed. This can be a helpful alternative to 
    #   calling {#unregister} on the relevant channel(s) by hand.
    # 
    # @raise [ArgumentError] if no ampersand-argument or inline block is 
    #   given as the +&callable+.
    #
    def register(*events, weak:false, &callable)
      raise ArgumentError, "No callable given to execute on event: #{events}" \
        unless callable.respond_to? :call
      events = Event.list_from *events
      
      ref = weak ? Ref::WeakReference.new(callable) :
                   Ref::StrongReference.new(callable)
      @@aim_lock.synchronize do
        @handlers << [events, ref]
        callable.extend RegisteredHandler
        callable.register_on_channel self
      end
      
      callable
    end
    
    module RegisteredHandler
      def register_on_channel(channel)
        (@registered_channels ||= []) << channel
      end
      
      def unregister
        @registered_channels.each do |c|
          c.unregister &self
        end.tap { @registered_channels = [] }
      end
    end
    
    # Unregister an event handler that was defined with #register
    #
    # @note It is not necessary to unregister event handlers 'owned' by
    #   persistent objects, but for short-lived objects, it is critical to
    #   to do so.  Due to the way that Proc objects (including those 
    #   generated implicitly from inline blocks) enclose their surrounding 
    #   scope, the +&callable+ handler will keep alive any objects it encloses,
    #   and the channel that holds a reference to the +&callable+ will keep it
    #   alive until it is unregistered.
    #
    # @note As an alternative to calling {Channel#unregister}, one may use
    #   the +#unregister+ method that was injected into the +&callable+ 
    #   (refer to the return value of {#register})
    #
    # @param callable [Proc] the same callable object that was given to 
    #   (and returned by) {#register}.
    #
    # @return [Boolean] +true+ if the callable was previously {#register}ed 
    #   (and is now {#unregister}ed); +false+ otherwise.
    #
    # @TODO break the GC note out into a dedicated document and link to it
    # @TODO try to remove all references to this channel object when it
    #   has no more handlers (and try to determine if this would ever be a 
    #   bad idea or would cause errant behavior) - possibly implement 
    #   Channel#forget instead?
    #
    def unregister(&callable)
      @@aim_lock.synchronize do
        !!@handlers.reject! do |stored|
          stored.last.object == callable
        end
      end
    end
    
    # Return the list of {#register}ed handlers for this channel
    #
    # @return [Array<Array(Array<Symbol,Event>,Proc)>] an array of arrays, each 
    #   containing an array of event patterns followed by the associated Proc.
    #
    def handlers
      @handlers.reject! { |_, ref| ref.object.nil? }
      @handlers.map { |events, ref| [events, ref.object] }
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
    # @param [Event, Symbol] event the event to be fired, as an Event or Symbol.
    #   In this context, a Symbol is treated as an 'empty' Event of that type
    #   (see to {Symbol#[]}).
    # @param [Boolean] blocking when true, the method will wait to return 
    #   until all handlers have finished their execution.
    # @param [Boolean] parallel when true, the handlers will be executed in 
    #   parallel, if there are more than one; otherwise, they will be executed
    #   serially (in an undefined order).  Unless otherwise specified, this 
    #   parameter will be set to the opposite of the value of the +:blocking+
    #   parameter; that is, nonblocking firing will by default also be parallel,
    #   and blocking firing will by default also be sequential.
    #
    # @return [Array<Thread>] the array of threads spawned by the method, 
    #   if any.  This could be useful for manually joining the threads later
    #   or monitoring their status.
    #
    # @raise An exception of the type and message contained in the 
    #   {#not_firable} attribute if it has been assigned by the active 
    #   {.router} through the {#not_firable=} accessor.
    #
    # @TODO Test the return array in each of the four concurrency cases
    #
    def fire(event, blocking: false, parallel: !blocking)
      raise *@not_firable if @not_firable
      
      return [] << Thread.new { fire(event, blocking:true, parallel:false) } \
        if !blocking and !parallel
      
      backtrace = caller
      
      event = event.to_wires_event
      
      self.class.send(:run_hooks, :@before_fire, event, self.name)
      
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
      
      self.class.send(:run_hooks, :@after_fire, event, self.name)
      
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
    
    # Synchronize execution of this thread to an incoming event.
    # The user block will be executed, and will not return until a matching
    # incoming event has been fired
    # (see the {SyncHelper})
    #
    # @note In order to use this method correctly, the "action" that causes the
    #   incoming event to be fired should happen within the user block.  If
    #   it happens before the user block, one risks a race condition; if after,
    #   one risks deadlock (or timeout) due to the feedback event being missed.
    #   As long as the feedback event happens after execution of the user block
    #   has begun, the event is guaranteed to be caught and processed.
    #
    # @param events [<Symbol, Event>] the event pattern(s) filter
    #   to listen with. (see {#register}).
    # @param timeout [Fixnum] the timeout, in seconds.
    #   (see {SyncHelper#wait}).
    # @param block [Proc] the user block. This block will be executed inline
    #   and passed an instance of {SyncHelper}.  Within this block, the helper
    #   should be configured using its methods.  Optionally, {SyncHelper#wait}
    #   can be called to wait in a specific location in the block.  Otherwise,
    #   it will be called implicitly at the end of the block.
    #
    # @!method sync_on(*events, timeout:nil, &block)
    def sync_on(*events, timeout:nil, &block)
      SyncHelper.new(events, self, timeout:timeout, &block)
      nil
    end
    
    # Helper class passed to user block in {Channel#sync_on} method.
    #   Read here for how to use the helper, but never instantiate it yourself.
    class SyncHelper
      
      # Don't instantiate this class directly, use {Channel#sync_on}
      # @api private
      def initialize(events, channel, timeout:nil)
        @timeout = timeout
        @lock, @cond = Mutex.new, ConditionVariable.new
        @conditions = []
        @executions = []
        @received   = []
        @thread     = Thread.current
        
        # Create the temporary event handler to capture incoming matches
        proc = Proc.new do |e,c|
          if Thread.current==@thread
            snag e,c
          else
            @lock.synchronize { snag e,c }
          end
        end
        
        # Run the user block within the lock and wait afterward if they didn't
        @lock.synchronize {
          channel.register events, &proc
          yield self
          wait unless @waited
          channel.unregister &proc
        }
      end
      
      # Add a condition which must be fulfilled for {#wait} to find a match.
      #
      # @param block [Proc] the block specifiying the condition to be met.
      #   It will be passed the event and channel, and the truthiness of its
      #   return value will be evaluated to determine if the condition is met.
      #   It will only be executed if the +[event,channel]+ pair fits the 
      #   filter and meets all of the other evaluated conditions so far.
      #    
      def condition(&block)
        @conditions << block if block
        nil
      end
      
      # Add a execution to run on the matching event for each {#wait}.
      #
      # @param block [Proc] the block to be executed.
      #   It will only be executed if the +[event,channel]+ pair fits the 
      #   filter and met all of the conditions to fulfill the {#wait}.
      #   The block will not be run if the {#wait} times out.
      #
      def execute(&block)
        @executions << block if block
        nil
      end
      
      # Wait for exactly one matching event meeting all {#condition}s to come.
      #
      # @note This will be called once implicitly at the end of the user block
      #   unless it gets called explicitly somewhere within the user block.
      #   It can be called multiple times within the user block to require
      #   one matching event each time within the block.
      #
      # @param timeout [Fixnum] The maximum time to wait for a match, 
      #   specified in seconds.  By default, it will be the number used at
      #   instantiation (passed from {Channel#sync_on}).
      #
      # @return the matching {Event} object, or nil if timed out.
      #
      def wait(timeout=@timeout)
        @waited = true
        result = nil
        
        # Loop through each result, making sure it matches the conditions,
        #   returning nil if the wait timed out and didn't push into @received
        loop do
          @cond.wait @lock, timeout if @received.empty?
          result = @received.pop
          return nil unless result
          break if !@conditions.detect { |blk| !blk.call *result }
        end
        
        # Run all the execute blocks on the result
        @executions.each { |blk| blk.call *result }
        result.first #=> return event
      end
      
    private
      
      # Snag the given event and channel to try it out in the blocking thread
      def snag(*args)
        @received << args
        @cond.signal # Pass execution back to blocking thread and block this one
      end
    end
    
    # Determine if one channel matches another.
    # 
    # In this context, a match indicates a receiver relationship.
    # That is, this method tests if +self+ is one of the {#receivers} of 
    # +other+. For a matching pair of channels, a {#fire}d event on the 
    # right-hand channel could be received by a relevant event handler on 
    # the left-hand channel. 
    #
    # Note that, depending on the strategy of the {.router}, this operator 
    # is not necessarily commutative. That is, having +a =~ b+ does not 
    # guarantee that +b =~ a+.
    #
    # @note Channel receiver relationships are entirely dictated by the 
    #   selected {.router}. Refer to the examples in the documentation for 
    #   {Router::Default} to learn about the routing patterns of the default
    #   router, but know that other {Router}s may be substituted as needed
    #   on a global basis with the {.router=} class-level accessor.
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
    
    # @return [Array<Channel>] the list of channels whose {#register}ed 
    #   event handlers would receive a relevant event {#fire}d by this channel.
    # 
    # @note (see Channel#=~)
    #
    def receivers
      self.class.router.get_receivers self
    end
    
  end
end
