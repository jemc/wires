
require 'wires'
include Wires

# Hub.run

# puts 'hey'

# 0.5.seconds.from_now do
#   puts 'hey'
# end

# sleep 1

# puts 'hey'

# Hub.kill :finish_all, :blocking


# proc = Proc.new{|e| p e}

# fib = Fiber.new{ proc.call('blah') }
# fib.resume
# p fib.resume

def foo(x)
  puts "hello"
  if x==5
    return 55
  elsif x==6
    return 66
  else
    return 0
  end
ensure
  puts "goodbye"
end

puts foo 5
puts foo 6
puts foo 0
      