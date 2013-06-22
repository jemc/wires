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
        x, state = x
        event, proc = x
        Thread.new do
            state[:lock] = false
            
            begin proc.call($event = event)
                
            rescue Interrupt, SystemExit => e
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
        state = {lock: true}
        @queue << [x, state]
        
        sleep(0) while state[:lock]
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