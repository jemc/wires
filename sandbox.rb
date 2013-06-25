require 'wires'

Hub.run

on :event do
    puts 'hey'
end

fire :event

sleep 0.5
Hub.kill # Stop process manually

