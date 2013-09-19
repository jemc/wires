
# Reopen the core Numeric class to add syntax sugar for 
# generating Wires::Duration objects
class ::Numeric
  
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
  unless instance_methods.include? #{k.last.inspect} \
      or instance_methods.include? #{k.first.inspect}
    
    def #{k.last}
      self * #{v}
    end
    alias #{k.first.inspect} #{k.last.inspect}
    
  end
CODE
  end
  
  # Reads best without arguments:  10.minutes.ago
  def ago(time = ::Time.now, &block)
    if block
      on :time_scheduler_anon, block.object_id do |e| block.call(e) end
      self.ago(time).fire(:time_scheduler_anon, block.object_id)
    end
    time - self
  end

  # Reads best with argument:  10.minutes.until(time)
  alias :until :ago

  # Reads best with argument:  10.minutes.since(time)
  def since(time = ::Time.now, &block)
    if block
      on :time_scheduler_anon, block.object_id do |e| block.call(e) end
      self.since(time).fire(:time_scheduler_anon, block.object_id)
    end
    time + self
  end

  # Reads best without arguments:  10.minutes.from_now
  alias :from_now :since
  
  
end

# Reopen the core Time class and add the fire method enabling nifty syntax like:
# 32.minutes.from_now.fire :event
class ::Time
  unless instance_methods.include? :fire
    def fire(event, channel='*', **kwargs)
      Wires::TimeScheduler.add(self, event, channel, **kwargs)
    end
  end
end