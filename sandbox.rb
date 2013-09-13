$LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
require 'wires'

# require 'wires/test'
# begin require 'jemc/reporter'; rescue LoadError; end

require 'ostruct'

class EventS < OpenStruct; end

require 'benchmark'

puts Benchmark.measure { 10000.times { EventS.new(dog:4).dog } }
puts Benchmark.measure { 10000.times { Wires::Event.new(dog:4).dog } }
puts Benchmark.measure { 10000.times { Wires::Event.new_from(cat:[dog:4]).dog } }
