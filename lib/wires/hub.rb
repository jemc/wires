
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An Event Hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
    @@queue = Queue.new
    @@running = false
    
    def self.running?; @@running; end
    
    # Start the Hub event loop in a new thread
    def self.run
        if not @@running
            @@running = true
            @@thread = Thread.new() {Hub.run_loop}
            at_exit { @@thread.join if not $! }
        end
    nil end
    
    # Start the Hub event loop in the current thread
    def self.run_in_place() 
        self.run_loop() unless @@running
    nil end
    
    # Kill the Hub event loop (softly)
    def self.kill() @@running=false end
    
    # Put x in the queue, and block until x is processed
    def self.fire(x)
        @@queue << [x, Thread.current]
        # yield to event loop thread until awoken by it later
        sleep unless not @@running
    end
    def self.<<(x) fire(x) end
    
private
    
    def self.run_loop
        @@running = true
            
        while @@running
            if @@queue.empty? then sleep(0)
            else process_item(@@queue.shift) end
        end
    end
    
    def self.process_item(x)
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
    
    def self.unhandled_exception(x)
        $stderr.puts $!
        $stderr.puts $@
    end
end
