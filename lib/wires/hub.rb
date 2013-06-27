
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An Event Hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
  @queue = Queue.new
  @running = false
  
  @before_kills = Queue.new
  @after_kills  = Queue.new
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    def running?; @running; end
    
    # Start the Hub event loop in a new thread
    def run
      if not @running
        @running = true
        @thread = Thread.new() {self.send(:run_loop)};
        at_exit { @thread.join if not $! }
      end
    nil end
    
    # Start the Hub event loop in the current thread
    def run_in_place()
      self.send(:run_loop) unless @running
    nil end
    
    # Kill the Hub event loop (softly)
    def kill(); 
      # Call the before kill hooks
      while not @before_kills.empty?
        @before_kills.shift.call
      end
      # Stop the main event loop
      @running=false;
    end
    
    # Register hook to execute before kill - can call multiple times
    def before_kill(proc=nil, &block)
      func = (block or proc)
      if not func.is_a?(Proc)
        raise TypeError, "Expected a Proc or code block to execute."
      end
      @before_kills << func
    end
    
    # Register hook to execute after kill - can call multiple times
    def after_kill(proc=nil, &block)
      func = (block or proc)
      if not func.is_a?(Proc)
        raise TypeError, "Expected a Proc or code block to execute."
      end
      @after_kills << func
    end
    
    # Put x in the queue, and block until x is processed
    def fire(x)
      @queue << [x, Thread.current]
      # yield to event loop thread until awoken by it later
      sleep unless not @running
    end
    def <<(x); fire(x); end
    
  private
    
    def run_loop
      @running = true
        
      while @running
        if @queue.empty? then sleep(0)
        else process_item(@queue.shift) end
      end
      
      while not @after_kills.empty?
        @after_kills.shift.call
      end
    end
    
    def process_item(x)
      x, waiting_thread = x
      string, event, blocking, proc = x
      Thread.new do
        begin
          waiting_thread.wakeup unless blocking
          proc.call($event = event)
          waiting_thread.wakeup if blocking
          
        rescue Interrupt, SystemExit => e
          @running = false
          unhandled_exception(e)
          
        rescue Exception => e
          unhandled_exception(e)
        end
      end
    end
    
    def unhandled_exception(x)
      $stderr.puts $!
      $stderr.puts $@
    end
  end
end
