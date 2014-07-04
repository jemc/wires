
# Implementation based on Thread::Pool::Task from the 'thread' gem
# (https://github.com/meh/ruby-thread)

module Wires.current_network::Namespace
  module Util
    class ThreadPool
      
      # A task incapsulates a block being ran by the pool and the arguments to pass
      # to it.
      class Task
        Timeout = Class.new(Exception)
        Asked   = Class.new(Exception)
        
        attr_reader :pool, :timeout, :exception, :thread, :started_at
        
        # Create a task in the given pool which will pass the arguments to the
        # block.
        def initialize (pool, *args, &block)
          @pool      = pool
          @arguments = args
          @block     = block
          
          @running    = false
          @finished   = false
          @timedout   = false
          @terminated = false
        end
        
        def running?;    @running;   end
        def finished?;   @finished;   end
        def timeout?;    @timedout;   end
        def terminated?; @terminated; end
        
        # Execute the task in the given thread.
        def execute (thread)
          return if terminated? || running? || finished?
          
          @thread     = thread
          @running    = true
          @started_at = Time.now
          
          pool.__send__ :wake_up_timeout
          
          begin
            @block.call(*@arguments)
          rescue Exception => reason
            if reason.is_a? Timeout
              @timedout = true
            elsif reason.is_a? Asked
              return
            else
              @exception = reason
            end
          end
          
          @running  = false
          @finished = true
          @thread   = nil
        end
        
        # Raise an exception in the thread used by the task.
        def raise (exception)
          @thread.raise(exception)
        end
        
        # Terminate the exception with an optionally given exception.
        def terminate! (exception = Asked)
          return if terminated? || finished? || timeout?
          
          @terminated = true
          
          return unless running?
          
          self.raise exception
        end
        
        # Force the task to timeout.
        def timeout!
          terminate! Timeout
        end
        
        # Timeout the task after the given time.
        def timeout_after (time)
          @timeout = time
          
          pool.timeout_for self, time
          
          self
        end
      end
      
    end
  end
end
