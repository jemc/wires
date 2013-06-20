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
        while true
            if @queue.empty? then sleep(0)
            else _process_item(@queue.shift) end
        end
    end
    
    def _process_item(x)
        event, proc = x
        Thread.new { proc.call($data = 55) }
    end
    
    def enqueue(x)
        @queue << x
    end
end

# Run the hub in a new thread
Thread.new do
    Hub.new.run
end