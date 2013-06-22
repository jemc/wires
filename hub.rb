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
                # TODO: This doesn't catch interrupts
                # outside the task threads, which means
                # that most of the time the interrupts will
                # not actually get caught, because the 
                # majority of time is spent idling in the
                # Hub's sleep loop.
                @keepgoing = false
                _unhandled_exception(e)
                
            rescue Exception => e
                _unhandled_exception(e)
            end
        end
    end
    
    def _unhandled_exception(x)
        $stderr.puts $!,$@
    end
    
    def fire(x)
        @queue << [x, Thread.current]
        sleep
    end
    
    def enqueue(x)
        fire x
    end
end

# Run the hub in a new thread
# __global_hub__ = Hub.new
Thread.new do
    Hub.new.run
    # __global_hub__.run
end