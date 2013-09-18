$LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
require 'wires'
include Wires

# require 'wires/test'
# begin require 'jemc/reporter'; rescue LoadError; end

# p Channel['*']   .relevant_channels
# p Channel['*']   .relevant_channels
# p Channel['abc'] .relevant_channels
# p Channel[/abc/] .relevant_channels 
# p Channel['abc'] .relevant_channels

# p Channel[/abc/]
# p Channel['abc']
# p Channel[:abc]

# p ChannelKeeper.table

# (on [dog:[55]], 'abc' do |e| p e end)



# class MyEvent < Wires::Event; end


# on [MyEvent=>[:dog]], 'Wires::Hub_B' do |e|
#   p 'whup'
#   # count.must_equal e.i
#   # count += 1
#   # fire_and_wait(MyEvent.new(i:(e.i+1)), 'Wires::Hub_B') if e.i < 9
#   # count.must_equal 10
# end

# fire_and_wait [MyEvent=>[:dog]], 'Wires::Hub_B'


# require 'benchmark'

# Benchmark.bm { |bm|
#   # bm.report { 1000000.times { :object.hash } }
#   # bm.report { 1000000.times { :object.to_sym.hash } }
#   # bm.report { 1000000.times { 'object'.hash } }
#   # bm.report { 1000000.times { 'object'.to_sym.hash } }
#   # bm.report { 1000000.times { ([3,4,5] + [4,5,6]) } }
#   # bm.report { 1000000.times { ([3,4,5] | [4,5,6]) } }
#   bm.report { 10000.times { fire_and_wait :dog, 'abc' } }
#   bm.report { 10000.times { fire :dog, 'abc' }; Wires::Hub.join_children }
# }


on :dogs do
  p 'whup'
end

fire :dogs, time:0.2.seconds.from_now, count:55

sleep 0.4