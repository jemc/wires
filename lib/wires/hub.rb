
#TODO: Allow custom grain times
module Wires
  # An Event Hub. Event/proc associations come in, and the procs 
  # get called in new threads in the order received
  class Hub
    # Operate on the metaclass as a type of singleton pattern
    class << self
      
      # Allow user to get/set limit to number of child threads
      attr_accessor :max_child_threads
      
      # Make subclasses call class_init
      def inherited(subcls); subcls.class_init end
      
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
        
        @before_runs = Queue.new
        @after_runs  = Queue.new
        @before_kills = Queue.new
        @after_kills  = Queue.new
        
        @please_finish_all = false
        
        @at_exit = Proc.new{nil}
        at_exit do self.at_exit_proc end
        
        state_machine_init
        
      nil end
      
      def at_exit_proc;  @at_exit.call;  end
      
      
      def dead?;  state==:dead  end
      def alive?; state==:alive end
      
      ##
      # Start the Hub to allow task spawning.
      #
      def run(*flags)
        sleep 0 until @spawning_count <= 0
        @spawning_count_lock.synchronize do
          sleep 0 until request_state :alive
        end
        spawn_neglected_task_threads
        join_children
      nil end
      
      ##
      # Kill the Hub event loop (optional flags change thread behavior)
      #
      # valid flags:
      # [+:nonblocking+]
      #   Without this flag, calling thread will be blocked
      #   until Hub thread is done
      # [+:purge_tasks+]
      #   Without this flag, Hub thread won't be done 
      #   until all child threads are done
      def kill(*flags)
        sleep 0 until @spawning_count <= 0
        # @spawning_count_lock.synchronize do
          @please_finish_all = (not flags.include? :purge_tasks)
          sleep 0 until request_state :dead unless (flags.include? :nonblocking)
        # end
      nil end
      
      # Register hook to execute before run - can call multiple times
      def before_run(retain=false, &block)
        @before_runs << [block, retain]
      nil end
      
      # Register hook to execute after run - can call multiple times
      def after_run(retain=false, &block)
        @after_runs << [block, retain]
      nil end
      
      # Register hook to execute before kill - can call multiple times
      def before_kill(retain=false, &block)
        @before_kills << [block, retain]
      nil end
      
      # Register hook to execute after kill - can call multiple times
      def after_kill(retain=false, &block)
        @after_kills << [block, retain]
      nil end
      
      # Spawn a task
      def spawn(*args) # :args: event, ch_string, proc, blocking
        @spawning_count_lock.synchronize { @spawning_count += 1 }
        
        return neglect(*args) if dead?
        
        event, ch_string, proc, blocking = *args
        
        # If blocking, run the proc in this thread
        if blocking
          proc.call(event, ch_string)
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
                                 (@max_child_threads <= @child_threads.size)
            # Start the new child thread; follow with chain of neglected tasks
            new_thread = Thread.new { proc.call(event, ch_string); \
                                      spawn_neglected_task_chain }
          # Capture ThreadError from either OS or user-set limitation
          rescue ThreadError; return neglect(*args); end
          
          @child_threads << new_thread
          return new_thread
        end
        
      ensure
        @spawning_count_lock.synchronize { @spawning_count -= 1 }
      end
      
      def purge_neglected
        @neglected_lock.synchronize do
          @neglected = Array.new
        end
      end
      
    private
      
      # Temporarily neglect a task until resources are available to run it
      def neglect(*args)
        $stderr.puts "#{self} neglected to spawn #{args.inspect}"
        @neglected_lock.synchronize do
          @neglected << args
        end
      false end
      
      # Run a chain of @neglected tasks in place until no more are waiting
      def spawn_neglected_task_chain
        neglected_one = nil
        @neglected_lock.synchronize do
          return nil if @neglected.empty?
          neglected_one = @neglected.shift
        end
        spawn(*((neglected_one)[0...-1]<<true)) # Call with blocking
        spawn_neglected_task_chain
      nil end
      
      # Flush @neglected task queue, each in a new thread
      def spawn_neglected_task_threads
        until (cease||=false)
          @neglected_lock.synchronize do
            break if (cease = @neglected.empty?)
            spawn(*((@neglected.shift)[0...-1]<<false)) # Call without blocking
          end
        end
      nil end
      
      # Flush/run queue of [proc, retain]s, retaining those with retain==true
      def run_hooks(hooks)
        retained = Queue.new
        while not hooks.empty?
          proc, retain = hooks.shift
          retained << [proc, retain] if retain
          proc.call
          # flush_queue if alive?
        end
        while not retained.empty?
          hooks << retained.shift
        end
      nil end
      
      # Join child threads, one by one, allowing more children to appear
      def join_children
        a_thread = Thread.new{nil}
        while a_thread
          @child_threads_lock.synchronize do
            # flush_queue
            a_thread = @child_threads.shift
          end
          a_thread.join if a_thread
          sleep 0 # Yield to other threads
        end
      nil end
      
    end
    
    
    #***
    # Initialize state machine properties
    #***
    class << self
      include Hegemon
      
      # Protect Hub users methods that could cause deadlock
      # if called from inside an event
      private :state_obj,
              :state_objs,
              :request_state,
              :update_state,
              :do_state_tasks,
              :iter_hegemon_auto_loop,
              :start_hegemon_auto_thread,
              :join_hegemon_auto_thread,
              :end_hegemon_auto_thread
      
      def state_machine_init
        
        impose_state :dead
        
        declare_state :dead do
          transition_to :alive do
            before { run_hooks @before_runs }
            after  { run_hooks @after_runs }
          end
        end
        
        declare_state :alive do
          transition_to :dead do
            before { run_hooks @before_kills }
            before { purge_neglected }
            before { join_children if @please_finish_all }
            after  { @please_finish_all = false }
            after  { run_hooks @after_kills }
          end
        end
        
      end
    end
    
    class_init
  end
end