
module Wires.current_network::Namespace
  
  module CoreExt
    module Symbol
      
      # Create a Wires::Event from any symbol with a payload of arguments
      def [](*args, **kwargs, &block)
        Event.new(*args, **kwargs, type:self, &block)
      end
      
      # Convert to a Wires::Event; returns an empty event with type:self
      def to_wires_event; self.[]; end
      
    end
  end
  
  class ::Symbol; include CoreExt::Symbol  end
  
end
