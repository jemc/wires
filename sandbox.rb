require_relative 'tubes'

def on_keypress(codeblock)
    event = 5
    codeblock.call($data = event)
end
def on(event, channel='*', &codeblock)
    # on_keypress(codeblock)
    Channel(channel).register(event, codeblock)
end


cow = 4

on :keyup do
    puts cow
    puts $data
end

on :keydown do
    puts cow
    puts $data
end

cow = 5
Channel('*').fire(:keyup)
cow = 6


Thread.new do
    Hub.new.run
end

sleep 2