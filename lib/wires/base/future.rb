
module Wires.current_network::Namespace
  
  # In this context, a {Future} is thread-safe container for a {#codeblock}
  # and for the {#result} produced when it is {#execute}d.
  #
  # Call {#execute} to run the block in place, or {#start} to {#execute} in
  # a new thread.  After {#execute} is done, the {#result} will be available.
  # Calling {#result} will block if {#execute} has not yet finished.
  # The block is guaranteed to run at most one time, so any subsequent 
  # calls to {#execute} will merely return the existing {#result}.
  # If running the block again is desired, use {#dup} to create a new {Future}
  # with the same {#codeblock}.
  #
  #   future = Future.new { |*args| expensive_operation *args }
  #   future.start 1,2,3 # Run expensive_operation in a thread with args=1,2,3
  #   # ...
  #   puts future.result # Block until expensive_operation is done and print result
  #
  # @note Primarily, {Future} is included in this library for the return value
  #   of {Launcher.spawn} (and, by extension, {Channel#fire}), but users should
  #   feel free to use it's documented API for other purposes as well.
  #
  class Future
    
    # The block passed at {#initialize} to be run when {#execute} is called.
    # It will be run at most one time.
    #
    attr_reader :codeblock
    
    # @param codeblock [Proc] The code block to run when {#execute} is called.
    # @raise [ArgumentError] If +codeblock+ is not given.
    #
    def initialize &codeblock
      raise ArgumentError, "Future must be instantiated with a block" \
        unless codeblock
      
      @codeblock = codeblock
      @state     = :initial
      @result    = nil
      @statelock = Mutex.new
      @cond      = ConditionVariable.new
    end
    
    # Run {#execute} in a new +Thread+. If {#execute} raises an +Exception+,
    # it will be rescued at the top level of the +Thread+, but will be raised
    # when {#result} is called.
    #
    # @param args The arguments to pass to {#codeblock} in {#execute}.
    # @param block The block argument to pass to {#codeblock} in {#execute}.
    # @return [Thread] The spawned +Thread+.
    #
    def start *args, &block
      Thread.new do
        begin
          execute *args, &block
        rescue Exception
          # Exceptions get raised through when #result is called.
        end
      end
    end
    
    # Run the {#codeblock} passed to {#initialize} with the given arguments.
    #
    # If the {#codeblock} has already been {#execute}d, it won't be run again;
    # instead, the result returned by the first call will be returned again.
    #
    # @param args The arguments to pass to {#codeblock}.
    # @param block The block argument to pass to {#codeblock}.
    # @return The return value of the call to {#codeblock}.
    # @raise The exception raised by the call to {#codeblock}, if any.
    #
    def execute *args, &block
      @statelock.synchronize do
        return @result if @state == :complete
        @state = :running
        
        begin
          @codeblock.call(*args, &block).tap do |result|
            @result = result
            @state  = :complete
          end
        rescue Exception => exception
          @result = exception
          @state  = :exception
          raise exception
        ensure
          @cond.broadcast
        end
      end
    end
    alias call execute
    
    # Get the return value of the call to {#codeblock}.
    #
    # If {#execute} has not yet been called, or if it is still {#running?},
    # {#result} will block until the {#codeblock} has been run.
    #
    # @return The return value of the call to {#codeblock}.
    # @raise The exception raised by the call to {#codeblock}, if any.
    #
    def result
      @statelock.synchronize do
        @cond.wait @statelock unless complete?
        @state==:exception ? raise(@result) : @result
      end
    end
    alias join result
    
    # @return [Boolean]
    #   +true+ if {#codeblock} is currently executing, else +false+.
    def running?;  @state == :running;  end
    alias executing? running?
    
    # @return [Boolean]
    #   +true+ if {#codeblock} has already executed, else +false+.
    def complete?; @state == :complete || @state == :exception; end
    alias ready? complete?
    
    # Duplicate the Future, without copying its {#running?}/{#complete?} state.
    # This is the preferred way to "reuse" a {Future}, because each {Future}
    # is guaranteed to run at most one time.  It is the same as creating a
    # new {Future} with the same {#codeblock} object passed to {#initialize}.
    #
    # @return [Future] A new {Future} with the same {#codeblock}.
    #
    def dup
      self.class.new &@codeblock
    end
    
  end
  
end
