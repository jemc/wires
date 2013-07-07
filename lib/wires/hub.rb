
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end

module Wires
  # An Event Hub. Event/proc associations come in, and the procs 
  # get called in new threads in the order received
  class Hub
    
    @queue = Queue.new
    
    @child_threads      = Array.new
    @child_threads_lock = Mutex.new
    
    @before_kills = Queue.new
    @after_kills  = Queue.new
    
    # Operate on the metaclass as a type of singleton pattern
    class << self
      
      def dead?;  state==:dead  end
      def alive?; state==:alive end
      
      ##
      # Start the Hub event loop (optional flags change thread behavior)
      #
      # valid flags:
      # [+:blocking+] Hub event loop will be run in calling thread,
      #               blocking until Hub is killed.  If this flag is not
      #               specified, the Hub event loop is run in a new thread, 
      #               which the main thread joins in at_exit.
      def run(*flags)
        request_state :alive until alive?
        
        # If :blocking, block now, else block at exit
        (flags.include? :blocking)   ?
          (join_hegemon_auto_thread) :
          (at_exit { join_hegemon_auto_thread unless $! })
      end
      
      ##
      # Kill the Hub event loop (optional flags change thread behavior)
      #
      # valid flags:
      # [+:finish_all+] Hub thread won't be done until all child threads done
      # [+:blocking+] calling thread won't be done until Hub thread is done
      def kill(*flags)
        @please_finish_all = (flags.include? :finish_all)
        @please_kill = true
        block_until_state :dead if (flags.include? :blocking)
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
        if not dead? # yield to event loop thread until awoken by it later
          @queue << [x, Thread.current]
          sleep
        else        # don't wait if Hub isn't running - would cause lockup
          @queue << [x, nil]
        end
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
            a_thread = @child_threads.shift
          end
          flush_queue if alive?
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
            waiting_thread.wakeup unless blocking or not waiting_thread
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
      def state_machine_init
        
        impose_state :dead
        
        declare_state :dead do
          # task { puts "I'm dead!" }
          
          transition_to :alive do
            after { start_hegemon_auto_thread }
          end
        end
        
        declare_state :alive do
          # task { puts "I'm alive!" }
          # task { sleep 0.05 } 
          task do
            # puts "task #{Thread.current.inspect}"; 
            if @queue.empty? then sleep(0)
            else process_item(@queue.shift) end
          end
          
          transition_to :dead do
            condition {@please_kill}
            
            before { run_hooks @before_kills }
            
            before { join_children if @please_finish_all }
            
            after  { run_hooks @after_kills  }
            
            after  { @please_kill = false }
            after  { @please_finish_all = false }
            
            after  { end_hegemon_auto_thread }
            after  { do_state_tasks }
          end
        end
        
      end
    end
    state_machine_init
    
  end
end