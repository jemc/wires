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

(on [dog:[55]], 'abc' do p 'yo' end)

# p Channel['abc'].target_list

fire_and_wait :dog, 'abc'


# require 'benchmark'

p Benchmark.bm { |bm|
  # bm.report { 1000000.times { :object.hash } }
  # bm.report { 1000000.times { :object.to_sym.hash } }
  # bm.report { 1000000.times { 'object'.hash } }
  # bm.report { 1000000.times { 'object'.to_sym.hash } }
  # bm.report { 1000000.times { ([3,4,5] + [4,5,6]) } }
  # bm.report { 1000000.times { ([3,4,5] | [4,5,6]) } }
  bm.report { 10000.times { fire_and_wait :dog, 'abc' } }
  bm.report { 10000.times { fire :dog, 'abc' }; Wires::Hub.join_children }
}

