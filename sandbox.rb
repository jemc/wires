require 'wires'

Hub.run

puts 'hey'

0.5.seconds.from_now do
  puts 'hey'
end

sleep 1

puts 'hey'

Hub.kill :finish_all, :blocking
