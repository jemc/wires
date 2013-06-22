require 'coderay'
# Wirb.start

# Make sure puts goes to $stdout for all threads!
def puts(x) $stdout.puts(x) end


class Hub
    def initialize
        @queue = Queue.new
    end
    
    def self.new
        @instance ||= super
    end
    
    def run
        @keepgoing = true
            
        while @keepgoing
            if @queue.empty? then sleep(0)
            else _process_item(@queue.shift) end
        end
        
    end
    
    def _process_item(x)
        x, waiting_thread = x
        event, proc = x
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
    
    def _unhandled_exception(x)
        $stderr.puts $!
        $stderr.puts $@
    end
    
    def fire(x)
        @queue << [x, Thread.current]
        sleep
    end
    
    def enqueue(x)
        fire x
    end
end


# Run the hub in a new thread and join it at main thread exit
#   However, do not join if an exception caused the exit - 
#     Such an exception indicates usually an error in user code
__hub_thread = Thread.new() {Hub.new.run}
at_exit { __hub_thread.join if not $! }
