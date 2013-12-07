
module Wires
  
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
    end
    
    # Assigns the given +name+ as the {#name} of this channel object
    #
    # @param name [#hash] a hashable object of any type, unique to this channel
    #
    def initialize(name)
      @name = name
      @handlers = {}
    end
    
    # Register an event handler to be executed when a matching event occurs.
    #
    # One or more event patterns should be passed as the arguments.
    # If an event matching one or more of the given event patterns is 
    # {#fire}d on a channel that has this channel as one of its {#receivers},
    # then the handler is executed, and yielded the event object and the {#name} 
    # of the channel upon which {#fire} was called as arguments.
    #
    # @param *events [<Symbol, Event>] the event pattern(s)
    #   to listen for. If the pattern is a symbol or event with a type and no 
    #   other arguments, any event with that type will be heard.  If the 
    #   pattern is an event that has other arguments, each of the arguments 
    #   and keyword arguments in the pattern must also be present in the
    #   fired event for it to be heard by the handler, but the fired event may
    #   also include other arguments that were not declared in the pattern
    #   and still be heard by the handler (see {Event#=~}).
    # @param &callable [Proc] the executable code to register as a handler 
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
    def register(*events, &callable)
      raise ArgumentError, "No callable given to execute on event: #{events}" \
        unless callable.respond_to? :call
      events = Event.list_from *events
      
      # Register the events under the callable in the @handlers hash
      @@aim_lock.synchronize do
        ary = (@handlers.has_key?(callable) ?
                 @handlers[callable]        :
                 @handlers[callable] = [])
        events.each { |e| ary << e unless ary.include? e }
      end
      
      # Insert the @registered_channels variable into the callable
      channels = callable.instance_variable_get(:@registered_channels)
      if channels
        channels << self
      else
        callable.instance_variable_set(:@registered_channels, [self])
      end
      
      # Insert the #unregister method into the callable
      callable.singleton_class.send :define_method, :unregister do
        singleton_class.send :remove_method, :unregister
        @registered_channels.each do |c|
          c.unregister &self
        end
      end unless callable.respond_to? :unregister
      
      callable
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
    # @param &callable [Proc] the same callable object that was given to 
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
        !!(@handlers.delete callable)
      end
    end
    
    # Return the list of {#register}ed handlers for this channel
    #
    # @return [Array<Array(Array<Symbol,Event>,Proc)>] an array of arrays, each 
    #   containing an array of event patterns followed by the associated Proc.
    #
    def handlers
      @handlers.map { |callable, events| [events, callable] }
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
    # @param [Boolean] :blocking when true, the method will wait to return 
    #   until all handlers have finished their execution.
    # @param [Boolean] :parallel when true, the handlers will be executed in 
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
              procs << pr if e =~ [event, 55, 55.6, 0x00, /regexp/, 'string', "string"]
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
