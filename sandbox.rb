require 'wires'

Hub.run

p Time.now
0.1.seconds.from_now.fire [:event, "A thing"]
0.1.seconds.from_now.fire [:event, "B thing"]
0.1.seconds.from_now.fire [:event, "C thing"]

on :event do
  puts "#{Time.now} : #{$event.inspect}"
end

# sleep 0.2

sleep 0.01 until TimeScheduler.list.empty?
Hub.kill(process_all:true)