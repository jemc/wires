require_relative 'tubes'

# TODO: handle exceptions in task threads
# TODO: allow firing multiple events and channels
# TODO: allow receiving multiple events and channels
# TODO: possibly have event handler filter with a hash of properties?
# TODO: possibly allow event handler filtering with regexp?
# TODO: pass events around as objects (optionally?)

on :keydown do
    sleep 1
    puts "event: #{$event}"
end

fire :keydown
