
# Add Time#fire for timed firing of events
::Time.class_eval <<-CODE
  def fire(event, channel='*', **kwargs)
    #{Wires::TimeScheduler}.add(self, event, channel, **kwargs)
  end
CODE
