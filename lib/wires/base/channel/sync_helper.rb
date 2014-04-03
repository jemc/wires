
module Wires.current_network::Namespace
  
  class Channel
    
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
    
  end
end
