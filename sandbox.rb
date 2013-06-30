require 'wires'

Hub.run

p Time.now
0.003.seconds.from_now.fire [:event, "A thing"]
0.001.seconds.from_now.fire [:event, "B thing"]
0.002.seconds.from_now.fire [:event, "C thing"]

on :event do
  puts "#{Time.now} : #{$event.inspect}"
end

sleep 0.5

puts 'killtime!'
Hub.kill