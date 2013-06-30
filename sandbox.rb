require 'wires'

Hub.run

count = 0
maxcount = 100

on :event do
  count += 1
  # puts "#{Time.now} : #{$event.inspect}"
  puts count
  fire_and_wait :event if count < maxcount
end

fire_and_wait :event

Hub.kill