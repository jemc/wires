require_relative 'tubes'


# TODO: overload '==' in Event to compare with symbol/string
#       >> e.is_a? Symbol or e.is_a? String
#       make BIDIRECTIONAL!

# TODO: allow listening on Channel(/regexp/) (but not firing to it!)

class KeyDownEvent < Event
end
class KeyUpEvent < Event
end


on [:key_down, :key_up], /A./ do
    puts "\nEvent on channel A:"
    p $event
end

on [:key_down, :key_up], /B./ do
    puts "\nEvent on channel B:"
    p $event
end


k = KeyDownEvent.new(55, 20, cow:30, blah:'string') {nil}
fire k

sleep 0.5

fire :key_up, 'A1'

sleep 0.5

fire [:key_up, 22, cow:30], 'chanB'

