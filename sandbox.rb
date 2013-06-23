require_relative 'tubes'

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
    puts "\nEvent on channel A:"
    p $event
end

on [:key_down, :key_up], 'chanB' do
    puts "\nEvent on channel B:"
    p $event
end


k = KeyDownEvent.new(55, 20, cow:30, blah:'string') {nil}
fire k

sleep 0.5

fire :key_up, 'chanA'

sleep 0.5

fire [:key_up, 22, cow:30], 'chanB'