
module Wires
  module Convenience
    
    @core_ext = true
    
    class << self
      
      # Set this attribute to false to disable core_ext on include
      attr_accessor :core_ext
      
      # Call extend_core on include unless attribute is set to false
      def included(*args)
        super
        self.extend_core if @core_ext
      end
      
      # Add methods to ::Time and ::Numeric
      def extend_core
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
end
