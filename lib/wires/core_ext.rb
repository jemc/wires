
module Wires
  module Convenience
    def self.included *args
      extend_core
    end

    def self.extend_core
      
      # Add Time#fire for timed firing of events
      ::Time.class_eval do
        def fire(event, channel='*', **kwargs)
          Wires::TimeScheduler.add(self, event, channel, **kwargs)
        end
      end
        
      # Add Numeric => Numeric time-factor converters
      {
        [:second,     :seconds]    => '1',
        [:minute,     :minutes]    => '60',
        [:hour,       :hours]      => '3600',
        [:day,        :days]       => '24.hours',
        [:week,       :weeks]      => '7.days',
        [:fortnight,  :fortnights] => '2.weeks',
      }.each_pair do |k,v|
        ::Numeric.class_eval <<-CODE
          def #{k.last}
            self * #{v}
          end
          alias #{k.first.inspect} #{k.last.inspect}
        CODE
      end
      
      # Add Numeric => Time converters with implicit anonymous fire
      {
        [:from_now, :since] => '+',
        [:until,    :ago]   => '-',
      }.each_pair do |k,v|
        ::Numeric.class_eval <<-CODE
          def #{k.last}(time = ::Time.now, &block)
            if block
              on :time_scheduler_anon, block.object_id do |e| block.call(e) end
              self.#{k.last}(time).fire(:time_scheduler_anon, block.object_id)
            end
            time #{v} self
          end
          alias #{k.first.inspect} #{k.last.inspect}
        CODE
      end
      
    end
  end
end