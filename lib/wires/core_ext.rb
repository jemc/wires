

# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class ::Time
  unless instance_methods.include? :fire
    def fire(event, channel='*', **kwargs)
      Wires::TimeScheduler << \
        Wires::TimeSchedulerItem.new(self, event, channel, **kwargs)
    end
  end
end

# Reopen the Numeric class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class Numeric
  
  {
    [:second,     :seconds]    => '1',
    [:minute,     :minutes]    => '60',
    [:hour,       :hours]      => '3600',
    [:day,        :days]       => '24.hours',
    [:week,       :weeks]      => '7.days',
    [:fortnight,  :fortnights] => '2.weeks',
    [:year,       :years]      => '365.242.days',
    [:decade,     :decades]    => '10.years',
    [:century,    :centuries]  => '100.years',
    [:millennium, :millennia]  => '1000.years',
  }.each_pair do |k,v|
    eval <<-CODE
    
  def #{k.last}
    Wires::Duration.new self * #{v}
  end
  alias #{k.first.inspect} #{k.last.inspect}
    
    CODE
  end
  
end


module Wires
  class Duration < ::BasicObject
    
    attr_accessor :value
    
    def ==(other)
      @value==other or (other.is_a?(Duration) and @value==other.value) or super
    end
    
    def initialize(value)
      @value = value
    end
    
    # Reads best without arguments:  10.minutes.ago
    def ago(time = ::Time.now, &block)
      if block
        on :time_scheduler_anon, block.object_id do |e| block.call(e) end
        self.ago(time).fire(:time_scheduler_anon, block.object_id)
      end
      time - @value
    end

    # Reads best with argument:  10.minutes.until(time)
    alias :until :ago

    # Reads best with argument:  10.minutes.since(time)
    def since(time = ::Time.now, &block)
      if block
        on :time_scheduler_anon, block.object_id do |e| block.call(e) end
        self.since(time).fire(:time_scheduler_anon, block.object_id)
      end
      time + @value
    end
    
    def method_missing(meth, *args, &block)
      @value.send(meth, *args, &block)
    end

    # Reads best without arguments:  10.minutes.from_now
    alias :from_now :since
    
  end
end



