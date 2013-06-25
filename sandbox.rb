require 'wires'

Hub.run!

class RegexpEvent < Event
end
# class AregexpEvent < Event
# end

on :event, /^reg/ do
   puts 'received at regexp'
end

# on :event, 'aregexp' do
#    puts 'received at string'
# end

fire :event, 'regexp'
# fire :event, 'aregexp'


sleep 0.5
Hub.kill! # Stop process manually
