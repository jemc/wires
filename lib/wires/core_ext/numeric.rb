
module Wires.current_network::Namespace
  
  module CoreExt
    module Numeric
      
      # Add Numeric => Numeric time-factor converters
      {
        [:second,     :seconds]    => 1,
        [:minute,     :minutes]    => 60,
        [:hour,       :hours]      => 60*60,
        [:day,        :days]       => 60*60*24,
        [:week,       :weeks]      => 60*60*24*7,
        [:fortnight,  :fortnights] => 60*60*24*7*2,
      }.each_pair do |symbols, multiplier|
        define_method(symbols.last) { self * multiplier }
        
        alias_method symbols.first, symbols.last
      end
      
      # Add Numeric => Time converters with implicit anonymous fire
      {
        [:from_now, :since] => :+,
        [:until,    :ago]   => :-,
      }.each_pair do |symbols, operator|
        channel = Channel[TimeScheduler]
        
        define_method symbols.last do |time = ::Time.now, &block|
          if block
            event = Event.new block: block, type: :time_scheduler_anon
            channel.register event, &block
            self.send(symbols.last, time).fire(event, channel)
          end
          time.send operator, self
        end
        
        alias_method symbols.first, symbols.last
      end
      
    end
  end
  
  ::Numeric.prepend CoreExt::Numeric
  
end
