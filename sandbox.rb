require 'wires'

Hub.run

on :event do
    puts "presleep: #{$event.val}"
    sleep 0.5
    puts "postsleep: #{$event.val}"
end

puts "\n fire_with_wait:"
for v in 0..3
    fire_and_wait [:event, val:v]
end

puts "\n fire:"
for v in 0..3
    fire [:event, val:v]
end


sleep 6
Hub.kill # Stop process manually

