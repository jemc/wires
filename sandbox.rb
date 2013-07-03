# TODO: Event.from_a, usable from all objects
# (Timescheduler events should convert to objects upon receiving)

# TODO: TS wakeup mutex

# TODO: thread-protect meta function - 
#   sync instance MONITOR to all functions specified
#  *re-entrant lock!!!
# Alternative - mixin that protects all public functions


require 'wires'

Hub.run

puts 'hey'

0.5.seconds.from_now do
  puts 'hey'
end

sleep 1

puts 'hey'

Hub.kill :finish_all, :blocking

