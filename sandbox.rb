require_relative 'tubes'

# TODO: fire function should block until event is actually fired
# TODO: handle exceptions in task threads
# TODO: allow firing multiple events and channels
# TODO: allow receiving multiple events and channels
# TODO: pass events around as objects (optionally?)

global_thing = 0

on :keydown do
    puts "something was pressed while global_thing was #{global_thing}"
end

on :keydown, 'keypad1' do
    puts "keypad1 was pressed while global_thing was #{global_thing}"
end


global_thing = 4

fire :keydown

global_thing = 5

sleep 0.5

fire :keydown, 'keypad1'

sleep 0.5