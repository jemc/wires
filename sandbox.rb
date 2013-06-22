require_relative 'tubes'

# TODO: allow firing multiple events and channels
# TODO: allow receiving multiple events and channels
# TODO: possibly have event handler filter with a hash of properties?
# TODO: possibly allow event handler filtering with regexp?
# TODO: pass events around as objects (optionally?)

class SomethingDoneEvent < Event
end
class SomethingElseDoneEvent < SomethingDoneEvent
end

p SomethingElseDoneEvent.ancestry
p SomethingElseDoneEvent.codestrings
p SomethingElseDoneEvent.codestring