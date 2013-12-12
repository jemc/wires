
module Wires.current_network::Namespace
  # An Event Hub. Event/proc associations come in, and the procs 
  # get called in new threads in the order received
  class Hub
    class << self
      
      # Refuse to instantiate; it's a singleton!
      private :new
      
      # Allow user to get/set limit to number of child threads
      attr_accessor :max_children
      
    private
    
      # Make subclasses call class_init
      def inherited(subcls); subcls.send(:class_init) end
      
      # Moved to a dedicated method for subclass' sake
      def class_init
        # @queue = Queue.new
        @max_children   = nil
        @children       = Array.new
        @children .extend MonitorMixin
        @neglected      = Array.new
        @neglected.extend MonitorMixin
        
        @hold_lock = Monitor.new
        
        reset_neglect_procs
        reset_handler_exception_proc
        
      nil end
      
    public
      
      def on_neglect(&block)
        @on_neglect=block
      nil end
      def on_neglect_done(&block)
        @on_neglect_done=block
      nil end
      def on_handler_exception(&block)
        @on_handler_exception=block
      nil end
      
      def reset_neglect_procs
        @on_neglect = Proc.new do |args|
          $stderr.puts "#{self} neglected to spawn task: #{args.inspect}"
        end
        @on_neglect_done = Proc.new do |args|
          $stderr.puts "#{self} finally spawned neglected task: #{args.inspect}"
        end
      nil end
      
      def reset_handler_exception_proc
        @on_handler_exception = Proc.new { raise }
      nil end
      
      # Execute a block while neglecting all child threads
      def hold
        @hold_lock.synchronize { yield }
        spawn_neglected_task_threads
      end
      
      # Spawn a task - user code should never call this directly
      def spawn(*args) # :args: event, chan, proc, blocking, parallel, fire_bt
        
        event, chan, proc, blocking, parallel, fire_bt = *args
        *proc_args = event, chan
        *exc_args  = event, chan, fire_bt
        
        # If not parallel, run the proc in this thread
        if !parallel
          begin
            proc.call(*proc_args)
          rescue Exception => exc
            unhandled_exception(exc, *exc_args)
          end
          
          return nil
        end
        
        return neglect(*args) \
          if @hold_lock.instance_variable_get(:@mon_mutex).locked?
        
        # If not parallel, clear old threads and spawn a new thread
        Thread.exclusive do
          begin
            # Raise ThreadError for user-set thread limit to mimic OS limit
            raise ThreadError if (@max_children) and \
                                 (@max_children <= @children.count)
            # Start the new child thread; follow with chain of neglected tasks
            @children << Thread.new do
              begin
                proc.call(*proc_args)
              rescue Exception => exc
                unhandled_exception(exc, *exc_args)
              ensure
                spawn_neglected_task_chain unless blocking
                @children.synchronize { @children.delete Thread.current }
              end
            end
            
          # Capture ThreadError from either OS or user-set limitation
          rescue ThreadError; return neglect(*args) end
          
          return @children.last
        end
        
      end
      
      def clear_neglected; @neglected.synchronize { @neglected.clear; nil } end
      def count_neglected; @neglected.synchronize { @neglected.count }      end
      
      # Join child threads, one by one, allowing more children to appear
      def join_children
        a_thread = nil
        loop do
          @children.synchronize do
            a_thread = @children.shift
          end
          break unless a_thread
          a_thread.join if ((a_thread) and (a_thread!=Thread.current))
          Thread.pass
        end
      nil end
      
    private
    
      # Send relevant data to a custom exception handler
      def unhandled_exception(exception, event, chan, fire_bt)
        class << exception;  attr_reader :fire_backtrace; end
        exception.instance_variable_set(:@fire_backtrace, fire_bt.dup)
        
        @on_handler_exception.call(exception, event, chan)
      end
      
      # Temporarily neglect a task until resources are available to run it
      def neglect(*args)
        @neglected.synchronize do
          @on_neglect.call(*args)
          @neglected << args
        end
      false end
      
      # Run a chain of @neglected tasks in place until no more are waiting
      def spawn_neglected_task_chain
        args = @neglected.synchronize do
          return nil if @neglected.empty?
          ((@neglected.shift)[0...-1]<<true) # Call with blocking
        end
        spawn(*args)
        @on_neglect_done.call(*args)
        spawn_neglected_task_chain
      nil end
      
      # Flush @neglected task queue, each in a new thread
      def spawn_neglected_task_threads
        until (cease||=false)
          args = @neglected.synchronize do
            break if (cease = @neglected.empty?)
            ((@neglected.shift)[0...-1]<<false) # Call without blocking
          end
          break if cease
          spawn(*args)
          @on_neglect_done.call(*args)
        end
      nil end
      
    end
    
    class_init
  end
end