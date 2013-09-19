
class Numeric
  
  def seconds
    Wires::Duration.new self
  end
  alias :second :seconds

  def minutes
    Wires::Duration.new self * 60
  end
  alias :minute :minutes

  def hours
    Wires::Duration.new self * 3600
  end
  alias :hour :hours

  def days
    Wires::Duration.new self * 24.hours
  end
  alias :day :days

  def weeks
    Wires::Duration.new self * 7.days
  end
  alias :week :weeks

  def fortnights
    Wires::Duration.new self * 2.weeks
  end
  alias :fortnight :fortnights

  def years
    Wires::Duration.new self * 365.242.days
  end
  alias :year :years

  def decades
    Wires::Duration.new self * 10.years
  end
  alias :decade :decades

  def centuries
    Wires::Duration.new self * 100.years
  end
  alias :century :centuries

  def millennia
    Wires::Duration.new self * 1000.years
  end
  alias :millennium :millennia

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

