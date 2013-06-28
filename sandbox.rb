require 'wires'





Hub.run

puts 'firing block'

1.seconds.from_now do 
  puts 'time-delayed block' 
end

sleep 2

puts 'killtime!'

Hub.kill