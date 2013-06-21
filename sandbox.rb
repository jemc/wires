require_relative 'tubes'

# TODO: handle exceptions in task threads
# TODO: allow firing multiple events and channels
# TODO: allow receiving multiple events and channels
# TODO: possibly have event handler filter with a hash of properties?
# TODO: possibly allow event handler filtering with regexp?
# TODO: pass events around as objects (optionally?)

global_thing = 0

on :keydown do
    puts "event: #{$event}, global_thing: #{global_thing}"
end

on :keydown, 'keypad1' do
    puts "event: #{$event}, global_thing: #{global_thing}"
end


global_thing = 4

fire :keydown

global_thing = 5

fire :keydown, 'keypad1'

global_thing = 6

fire :keydown, 'keypad1'


sleep 0.5