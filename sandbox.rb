require 'wires'

Hub.run

count = 0
maxcount = 4

on :event do
  count += 1
  # puts "#{Time.now} : #{$event.inspect}"
  puts count
  sleep 0.5
  puts 'done'
  if count == 4 then Hub.kill end
end

4.times do fire :event end

# sleep 0.2
# Hub.kill_children

Hub.run :blocking
# Hub.kill :finish_all, :blocking

# Hub.kill
# Hub.kill_blocking
# Hub.kill_when_done
# Hub.kill_when_done_blocking