
module Wires
  # An Event Hub. Event/proc associations come in, and the procs 
  # get called in new threads in the order received
  class self::Hub
    class << self
      
      # Allow user to get/set limit to number of child threads
      attr_accessor :max_child_threads
      
    private
    
      # Make subclasses call class_init
      def inherited(subcls); subcls.send(:class_init) end
      
      # Moved to a dedicated method for subclass' sake
      def class_init
        # @queue = Queue.new
        @max_child_threads   = nil
        @child_threads       = Array.new
        @child_threads_lock  = Monitor.new
        @neglected           = Array.new
        @neglected_lock      = Monitor.new
        @spawning_count      = 0
        @spawning_count_lock = Monitor.new
        
        @before_runs  = Queue.new
        @after_runs   = Queue.new
        @before_kills = Queue.new
        @after_kills  = Queue.new
        @before_fires = []
        @after_fires  = []
        
        @please_finish_all = false
        
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
      
      # Spawn a task
      def spawn(*args) # :args: event, ch_string, proc, blocking, fire_bt
        
        @spawning_count_lock.synchronize { @spawning_count += 1 }
        
        return neglect(*args) if dead?
        
        event, ch_string, proc, blocking, fire_bt = *args
        *proc_args = event, ch_string
        *exc_args  = event, ch_string, fire_bt
        
        # If blocking, run the proc in this thread
        if blocking
          begin
            proc.call(*proc_args)
          rescue Exception => exc
            unhandled_exception(exc, *exc_args)
          end
          
          return :done
        end
        
        # If not blocking, clear old threads and spawn a new thread
        new_thread = nil
        
        @child_threads_lock.synchronize do
          
          # Clear out dead threads
          @child_threads.select!{|t| t.status}
          
          begin
            # Raise ThreadError for user-set thread limit to mimic OS limit
            raise ThreadError if (@max_child_threads) and \
                                 (@max_child_threads <= @child_threads.count)
            # Start the new child thread; follow with chain of neglected tasks
            new_thread = Thread.new do
              begin
                proc.call(*proc_args)
              rescue Exception => exc
                unhandled_exception(exc, *exc_args)
              ensure
                spawn_neglected_task_chain
              end
            end
            
          # Capture ThreadError from either OS or user-set limitation
          rescue ThreadError; return neglect(*args) end
          
          @child_threads << new_thread
          return new_thread
        end
        
      ensure
        @spawning_count_lock.synchronize { @spawning_count -= 1 }
      end
      
      def purge_neglected
        @neglected_lock.synchronize do
          @neglected.clear
        end
      nil end
      
      def number_neglected
        @neglected_lock.synchronize do
          @neglected.count
        end
      end
      
      # Join child threads, one by one, allowing more children to appear
      def join_children
        a_thread = Thread.new{nil}
        while a_thread
          @child_threads_lock.synchronize do
            a_thread = @child_threads.shift
          end
          a_thread.join if ((a_thread) and (a_thread!=Thread.current))
          sleep 0 # Yield to other threads
        end
      nil end
      
    private
    
      # Send relevant data to a custom exception handler
      def unhandled_exception(exception, event, ch_string, fire_bt)
        
        class << exception;  attr_reader :fire_backtrace; end
        exception.instance_variable_set(:@fire_backtrace, fire_bt.dup)
        
        @on_handler_exception.call(exception, event, ch_string)
        
      end
      
      # Temporarily neglect a task until resources are available to run it
      def neglect(*args)
        @neglected_lock.synchronize do
          @on_neglect.call(*args)
          @neglected << args
        end
      false end
      
      # Run a chain of @neglected tasks in place until no more are waiting
      def spawn_neglected_task_chain
        args = @neglected_lock.synchronize do
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
          args = @neglected_lock.synchronize do
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