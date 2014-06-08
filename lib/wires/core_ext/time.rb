
module Wires.current_network::Namespace
  
  module CoreExt
    module Time
      
      # Timed firing of events
      def fire(events, channel, **kwargs)
        TimeScheduler.add(self, events, channel, **kwargs)
      end
      
    end
  end
  
  class ::Time; include CoreExt::Time  end
  
end
