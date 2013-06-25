
# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


# An event hub. Event/proc associations come in, and the procs 
# get called in new threads in the order received
class Hub
    @@queue = Queue.new
    
    def self._run
        @@keepgoing = true
            
        while @@keepgoing
            if @@queue.empty? then sleep(0)
            else _process_item(@@queue.shift) end
        end
    end
    
    def self.run!
        @@thread = Thread.new() {Hub._run}
        at_exit { @@thread.join if not $! }
    end
    
    def self.run_in_place!() self._run() end
    
    def self.kill!() @@keepgoing=false end
    
    def self._process_item(x)
        x, waiting_thread = x
        string, event, proc = x
        Thread.new do
            
            begin
                waiting_thread.wakeup
                proc.call($event = event)
                
            rescue Interrupt, SystemExit => e
                @keepgoing = false
                _unhandled_exception(e)
                
            rescue Exception => e
                _unhandled_exception(e)
            end
        end
    end
    
    def self._unhandled_exception(x)
        $stderr.puts $!
        $stderr.puts $@
    end
    
    def self.fire(x)
        @@queue << [x, Thread.current]
        sleep
    end
    
    def self.enqueue(x) fire(x) end
    def self.<<(x)      fire(x) end
    
    private_class_method :new
end


