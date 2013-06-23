require_relative 'tubes'

# TODO: handle arguments to events

# TODO: overload '==' in Event to compare with symbol/string
#       >> e.is_a? Symbol or e.is_a? String
#       make BIDIRECTIONAL!

# TODO: consider all possible class names for events and
#       be sure that codestrings are compatible

# TODO: possibly have event handler filter with a hash of properties?
# TODO: possibly allow event handler filtering with regexp?

class KeyDownEvent < Event
end
class KeyUpEvent < Event
end


on [:key_down, :key_up], 'chanA' do
    p "#{$event} event on channel A"
end

on [:key_down, :key_up], 'chanB' do
    p "#{$event} event on channel B"
end

# fire :key_down
sleep 0.5
fire :key_up, "chanB"
