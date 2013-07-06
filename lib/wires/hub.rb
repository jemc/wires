
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An Event Hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
  @queue = Queue.new
  @state = [:dead, :alive, :dying][0]
  
  @child_threads      = Array.new
  @child_threads_lock = Mutex.new
  
  @before_kills = Queue.new
  @after_kills  = Queue.new
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    def dead?;  @state==:dead  end
    def alive?; @state==:alive end
    def dying?; @state==:dying end
    def state;  @state         end
    
    # Clear the Hub queue, but do not kill working threads
    def clear;  @queue.clear   end
    
    ##
    # Start the Hub event loop (optional flags change thread behavior)
    #
    # valid flags:
    # [+:blocking+] Hub event loop will be run in calling thread,
    #               blocking until Hub is killed.  If this flag is not
    #               specified, the Hub event loop is run in a new thread, 
    #               which the main thread joins in at_exit.
    def run(*flags)
      if dead? # Only run if not already alive or dying
        
        # If :blocking is not set, run in a new thread and join at_exit
        if not (flags.include? :blocking)
          @thread = Thread.new() do
            self.send(:run_loop)
          end
          # Only join if main thread wasn't killed by an exception
          at_exit { @thread.join if not $! }
        
        # If :blocking is set, run in main thread and block until Hub death
        else self.send(:run_loop) end
        
      end
      
      sleep 0 # Yield to other threads
      
    nil end
    
    ##
    # Kill the Hub event loop (optional flags change thread behavior)
    #
    # valid flags:
    # [+:finish_all+] Hub thread won't be done until all child threads done
    # [+:blocking+] calling thread won't be done until Hub thread is done
    def kill(*flags)
      @finish_all = (flags.include? :finish_all)
      @state=:dying
      @thread.join if (dying? and flags.include? :blocking)
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
    
  private
  
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
    
    # Join child threads, one by one, allowing more children to appear
    def join_children
      a_thread = Thread.new{nil}
      while a_thread
        @child_threads_lock.synchronize do
          a_thread = @child_threads.shift
        end
        a_thread.join if a_thread
        sleep 0 # Yield to other threads
      end
    nil end
    
    # Flush/run queue of [proc, retain]s, retaining those with retain==true
    def run_hooks(queue)
      retained = Queue.new
      while not queue.empty?
        proc, retain = queue.shift
        retained << [proc, retain] if retain
        proc.call
      end
      while not retained.empty?
        queue << retained.shift
      end
    nil end
  
    # Run before_kill hooks, optionally join child threads, then die
    def die
      run_hooks(@before_kills)
      join_children if @finish_all
      @state = :dead
    nil end
    
    # Run main event loop, not finished until Hub is killed
    def run_loop
      @state = :alive
        
      while not dead?
        if @queue.empty? then sleep(0)
        else process_item(@queue.shift) end
        
        if dying?
          die_thread ||= Thread.new { die }
        end
      end
      
      run_hooks(@after_kills)
      @finish_all = false
      
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
          begin
            waiting_thread.wakeup unless blocking or not waiting_thread
            proc.call(event)
            waiting_thread.wakeup if blocking and waiting_thread
            
          rescue Interrupt, SystemExit => e
            @state = :dying
            unhandled_exception(e)
            
          rescue Exception => e
            unhandled_exception(e)
          end
        end
        
      end
    
    nil end
    
    def unhandled_exception(x)
      $stderr.puts $!
      $stderr.puts $@
    nil end
  end
end
