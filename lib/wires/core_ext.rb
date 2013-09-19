
# Reopen the Time class and add the fire method to enable nifty syntax like:
# 32.minutes.from_now.fire :event
class ::Time
  unless instance_methods.include? :fire
    def fire(event, channel='*', **kwargs)
      Wires::TimeScheduler.add(self, event, channel, **kwargs)
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
