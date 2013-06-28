require 'wires'

Hub.run
TimeScheduler.grain = 0.1.seconds

p Time.now
3.seconds.from_now.fire [:event, "A thing"]
1.seconds.from_now.fire [:event, "B thing"]
2.seconds.from_now.fire [:event, "C thing"]

on :event do
  puts "#{Time.now} : #{$event.inspect}"
end

sleep 4

puts 'killtime!'
Hub.kill