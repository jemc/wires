require_relative 'tubes'

# TODO: allow firing multiple events and channels
# TODO: allow receiving multiple events and channels
# TODO: possibly have event handler filter with a hash of properties?
# TODO: possibly allow event handler filtering with regexp?
# TODO: pass events around as objects (optionally?)

on :keydown do
    raise NotImplementedError
    sleep 1
    puts "event: #{$event}"
end

on 'keydown' # do nothing

# fire :keydown
# fire 'keydown'
