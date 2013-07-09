
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end

module Wires
  # An Event Hub. Event/proc associations come in, and the procs 
  # get called in new threads in the order received
  class Hub
    # Operate on the metaclass as a type of singleton pattern
    class << self
      
      # Moved to a dedicated method for subclass' sake
      def class_init
        @queue = Queue.new
        
        @child_threads      = Array.new
        @child_threads_lock = Monitor.new
        
        @before_runs = Queue.new
        @after_runs  = Queue.new
        @before_kills = Queue.new
        @after_kills  = Queue.new
        
        @please_finish_all = false
        @please_kill       = false
        
        @at_exit = Proc.new{nil}
        at_exit do self.at_exit_proc end
        
        state_machine_init
        
      nil end
      
      def at_exit_proc;  @at_exit.call;  end
      
      # Make subclasses call class_init
      def inherited(subcls); subcls.class_init end
      
      
      def dead?;  state==:dead  end
      def alive?; state==:alive end
      
      ##
      # Start the Hub event loop (optional flags change thread behavior)
      #
      # valid flags:
      # [+:in_place+] Hub event loop will be run in calling thread,
      #               blocking until Hub is killed.  If this flag is not
      #               specified, the Hub event loop is run in a new thread, 
      #               which the main thread joins in at_exit.
      def run(*flags)
        request_state :alive until alive?
        
        # If :blocking, block now, else block at exit
        (flags.include? :in_place)   ?
          (@thread.join) :
          (@at_exit = Proc.new { @thread.join if @thread and not $! })
      end
      
      ##
      # Kill the Hub event loop (optional flags change thread behavior)
      #
      # valid flags:
      # [+:nonblocking+]
      #   Without this flag, calling thread will be blocked
      #   until Hub thread is done
      # [+:purge_events+]
      #   Without this flag, Hub thread won't be done 
      #   until all child threads are done
      def kill(*flags)
        @please_finish_all = (not flags.include? :purge_events)
        @please_kill = true
        block_until_state :dead unless (flags.include? :nonblocking)
      nil end
      
      # Register hook to execute before run - can call multiple times
      def before_run(proc=nil, retain:false, &block)
        func = (block or proc)
        expect_type func, Proc
        @before_runs << [func, retain]
      nil end
      
      # Register hook to execute after run - can call multiple times
      def after_run(proc=nil, retain:false, &block)
        func = (block or proc)
        expect_type func, Proc
        @after_runs << [func, retain]
      nil end
      
      # Register hook to execute before kill - can call multiple times
      def before_kill(proc=nil, retain:false, &block)
        func = (block or proc)
        expect_type func, Proc
        @before_kills << [func, retain]
      nil end
      
      # Register hook to execute after kill - can call multiple times
      def after_kill(proc=nil, retain:false, &block)
        func = (block or proc)
        expect_type func, Proc
        @after_kills << [func, retain]
      nil end
      
      # Put x in the queue, and block until x is processed (if Hub is running)
      def fire(x)
        raise ThreadError, "You can't fire events from this thread." \
          if Thread.current==@_hegemon_auto_thread \
          or Thread.current==@thread
        
        @queue << [x, Thread.current]
        (x[2] and @thread) ?
          sleep            :
          Thread.pass
        
      nil end
      def <<(x); fire(x); end
      
      def flush_queue
        (process_item(@queue.shift) until @queue.empty?)
      end
      
      
    private
      
      # Flush/run queue of [proc, retain]s, retaining those with retain==true
      def run_hooks(hooks)
        retained = Queue.new
        while not hooks.empty?
          proc, retain = hooks.shift
          retained << [proc, retain] if retain
          proc.call
          flush_queue if alive?
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
            flush_queue
            a_thread = @child_threads.shift
          end
          a_thread.join if a_thread
          sleep 0 # Yield to other threads
        end
      nil end
      
      # Kill all currently working child threads
      # Newly fired events could still queue up, 
      # Waiting to be born until this thread is done killing
      def kill_children
        @child_threads_lock.synchronize do
          until @child_threads.empty?
            @child_threads.shift.exit
          end
        end
      nil end
      
      # Kill all currently working child threads
      # Newly fired events could still queue up, 
      # But they will be cleared out and never be born
      def kill_children_and_clear
        @child_threads_lock.synchronize do
          until @child_threads.empty?
            @child_threads.shift.exit
          end
          clear
        end
      nil end
      
      def process_item(x)
        x, waiting_thread = x
        string, event, blocking, proc = x
        
        # Do all dealings with @child_threads under mutex
        @child_threads_lock.synchronize do
          
          # Clear dead child threads to free up memory
          @child_threads.select! {|t| t.status}
          
          # Start the new child thread
          @child_threads << Thread.new do
            proc.call(event)
            waiting_thread.wakeup if blocking and waiting_thread
          end
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
            after  { do_state_tasks }
            after  { start_hegemon_auto_thread(0.1) }
          end
        end
        
        declare_state :alive do
          
          task do |i|
            
            @thread = Thread.new do
              while true
                if @queue.empty? then sleep 0.1
                else process_item(@queue.shift) end
              end
            end if i==0
            
          end
          
          transition_to :dead do
            condition {@please_kill}
            
            before { run_hooks @before_kills }
            
            before { join_children if @please_finish_all }
            
            after  { @thread.kill; @thread = nil}
            
            after  { @please_kill = false }
            after  { @please_finish_all = false }
            
            after  { run_hooks @after_kills }
            
            after  { end_hegemon_auto_thread }
            after  { do_state_tasks }
          end
        end
        
      end
    end
    
    class_init
  end
end