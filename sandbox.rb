require_relative 'tubes'


# TODO: overload '==' in Event to compare with symbol/string
#       >> e.is_a? Symbol or e.is_a? String
#       make BIDIRECTIONAL!

# TODO: allow listening on objects for channels that get resolved with to_s

# TODO: allow listening on Channel(/regexp/) (but not firing to it!)


# class KeyDownEvent < Event
# end
# class KeyUpEvent < Event
# end


# on [:key_down, :key_up], /A./ do
#     puts "\nEvent on channel A:"
#     p $event
# end

# on [:key_down, :key_up], /B./ do
#     puts "\nEvent on channel B:"
#     p $event
# end


# k = KeyDownEvent.new(55, 20, cow:30, blah:'string') {nil}
# fire k

# sleep 0.5

# fire :key_up, 'A1'

# sleep 0.5

# fire [:key_up, 22, cow:30], 'chanB'

# class A
#     def self.==(other)
#         p "s==A - #{other}"
#     end
# end

# class B < A
# end

# class Symbol
#     def ==(other)
#         p "A==s - #{other}"
#         super
#     end
# end

# A == :symbol
# p :symbol == A

# case B
# when Class and (B<A)
#     puts 'yay'
# else
#     puts 'meh'
# end

# class FWHub < Hub
# end

# class FWChannel < Channel
#     @@channel_list = Set.new
#     @@hub = FWHub.new
# end

# puts Hub.new
# puts FWHub.new
# puts FWHub.new
# puts Channel.new('a')
# puts FWChannel.new('a')


