
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An Event Hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
  @queue = Queue.new
  @state = [:dead, :alive, :dying][0]
  
  @before_kills = Queue.new
  @after_kills  = Queue.new
  
  # Operate on the metaclass as a type of singleton pattern
  class << self
    
    def dead?;  @state==:dead  end
    def alive?; @state==:alive end
    def dying?; @state==:dying end
    def state;  @state         end
    
    def clear;  @queue.clear   end
    
    # Start the Hub event loop in a new thread
    def run
      if dead?
        @thread = Thread.new() do
          self.send(:run_loop)
        end
        
        at_exit { @thread.join if not $! }
      end
    nil end
    
    # Start the Hub event loop in the current thread
    def run_in_place()
      self.send(:run_loop) if dead?
    nil end
    
    # Kill the Hub event loop (softly)
    def kill()
      # Stop the main event loop
      @state=:dying if alive?
    nil end
    
    def kill_and_wait()
      kill
      @thread.join
    nil end
    
    # Register hook to execute before kill - can call multiple times
    def before_kill(proc=nil, &block)
      func = (block or proc)
      if not func.is_a?(Proc)
        raise TypeError, "Expected a Proc or code block to execute."
      end
      @before_kills << func
    nil end
    
    # Register hook to execute after kill - can call multiple times
    def after_kill(proc=nil, &block)
      func = (block or proc)
      if not func.is_a?(Proc)
        raise TypeError, "Expected a Proc or code block to execute."
      end
      @after_kills << func
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
  
    def die
      # Call the before kill hooks # TODO move
      while not @before_kills.empty?
        @before_kills.shift.call
      end
      @state = :dead
    nil end
    
    def run_loop
      @state = :alive
        
      while not dead?
        if @queue.empty? then sleep(0)
        else process_item(@queue.shift) end
        
        if dying?; die_thread ||= Thread.new { die } end
      end
      
      while not @after_kills.empty?
        @after_kills.shift.call
      end
    nil end
    
    def process_item(x)
      x, waiting_thread = x
      string, event, blocking, proc = x
      Thread.new do
        begin
          waiting_thread.wakeup unless blocking or not waiting_thread
          proc.call($event = event)
          waiting_thread.wakeup if blocking and waiting_thread
          
        rescue Interrupt, SystemExit => e
          @state = :dying
          unhandled_exception(e)
          
        rescue Exception => e
          unhandled_exception(e)
        end
      end
    nil end
    
    def unhandled_exception(x)
      $stderr.puts $!
      $stderr.puts $@
    nil end
  end
end
