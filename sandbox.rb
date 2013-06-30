require 'wires'

Hub.run

0.2.seconds.from_now do
  puts 'hey'
end

sleep 0.5

Hub.kill :finish_all, :blocking
