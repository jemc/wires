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

# on :dog, 'abc' do p 'yo' end

# fire :dog, 'abc'


# require 'benchmark'

# p Benchmark.bm { |bm|
#   bm.report { 1000000.times { :object.hash } }
#   bm.report { 1000000.times { :object.to_sym.hash } }
#   bm.report { 1000000.times { 'object'.hash } }
#   bm.report { 1000000.times { 'object'.to_sym.hash } }
#   bm.report { 1000000.times { ([3,4,5] + [4,5,6]) } }
#   bm.report { 1000000.times { ([3,4,5] | [4,5,6]) } }
# }

p Wires::Event.new_from(:my=>[44,22], Wires::Event=>[44,22, args:['cow']])
  .map{ |e| e.kwargs }