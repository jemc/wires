
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An Event Hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
    @@queue = Queue.new
    
    # Start the Hub event loop in a new thread
    def self.run
        @@thread = Thread.new() {Hub.run_loop}
        at_exit { @@thread.join if not $! }
    end
    
    # Start the Hub event loop in the current thread
    def self.run_in_place() self.run_loop() end
    
    # Kill the Hub event loop (softly)
    def self.kill() @@keepgoing=false end
    
    # Put x in the queue, and block until x is processed
    def self.fire(x)
        @@queue << [x, Thread.current]
        sleep # yield to event loop thread until awoken by it later
    end
    def self.<<(x) fire(x) end
    
private
    
    def self.run_loop
        @@keepgoing = true
            
        while @@keepgoing
            if @@queue.empty? then sleep(0)
            else process_item(@@queue.shift) end
        end
    end
    
    def self.process_item(x)
        x, waiting_thread = x
        string, event, proc = x
        Thread.new do
            begin
                waiting_thread.wakeup
                proc.call($event = event)
                
            rescue Interrupt, SystemExit => e
                @keepgoing = false
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
