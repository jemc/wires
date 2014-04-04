
module Wires.current_network::Namespace
  
  class Future
    
    attr_reader :codeblock
    
    def initialize(&block)
      raise ArgumentError, "Future must be instantiated with a block" \
        unless block
      
      @codeblock = block
    end
    
    def execute *args, &block
      @codeblock.call *args, &block
    end
    
  end
  
end
