require 'wires'


on :event, /^reg/ do
   puts 'received at regexp'
end

on :event, 'aregexp' do
   puts 'received at string'
end

fire :event, 'regexp'
fire :event, 'aregexp'


sleep 0.25
Hub.new.kill! # Stop process manually
