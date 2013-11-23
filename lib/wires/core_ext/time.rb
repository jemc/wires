
# Add Time#fire for timed firing of events
class ::Time
  def fire(events, channel, **kwargs)
    Wires::TimeScheduler.add(self, events, channel, **kwargs)
  end
end
