
module Wires.current_network::Namespace
  
  class Future
    
    attr_reader :codeblock
    
    def initialize(&block)
      raise ArgumentError, "Future must be instantiated with a block" \
        unless block
      
      @codeblock = block
      @state     = :initial
      @result    = nil
      @statelock = Mutex.new
      @cond      = ConditionVariable.new
    end
    
    def start *args, &block
      Thread.new { execute *args, &block }
    end
    
    def execute *args, &block
      @statelock.synchronize do
        return @result if @state == :complete
        @state = :running
        
        @codeblock.call(*args, &block).tap do |result|
          @result = result
          @state  = :complete
          @cond.broadcast
        end
      end
    end
    
    def join
      @statelock.synchronize do
        @cond.wait @statelock unless complete?
        @result
      end
    end
    alias result join
    
    def running?;  @state == :running;  end;  alias executing? running?
    def complete?; @state == :complete; end;  alias ready? complete?
    
  end
  
end
