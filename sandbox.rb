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
  p "whup: #{Time.now}"
  fire :dogs, time:0.01.seconds.from_now, count:55
end

fire :dogs, time:0.01.seconds.from_now, count:55

sleep 100


# require "thread"
# require "monitor"
 
# # Create our queue
# q = Array.new
# m = Monitor.new
# # Using our queue itself as our monitor
# # q.extend(MonitorMixin)
# # Adding the numbers we want to calculate for
# q << 3 << 10 << 10000 << 2352352
# # Keep track of how many results we have yet to process
# results_unprocessed = q.length
 
# cond = m.new_cond
 
# threads = []
# 10.times do
#   threads << Thread.new do 
#     num = q.pop
#     # marker 1
#     puts "#{num}: " + calculate_fibonacci_for(num)
#     # we're changing a condition of the monitor, so we need to synchronize
#     m.synchronize do
#       # updating condition
#       results_unprocessed -= 1
#       cond.broadcast
#     end
#   end
# end
 
# # m.synchronize do
#   cond.wait_while do
#     # check condition here
#     results_unprocessed > 0
#   end
#   # could have also done cond.wait_until { results_unprocessed == 0 }
# # end



# require 'monitor'

# buf = []
# buf.extend(MonitorMixin) # 配列にモニタ機能を追加
# empty_cond = buf.new_cond # 配列が空であるかないかを通知する条件変数

# # consumer
# Thread.start do
#   loop do
#     # p 'beh'
#     buf.synchronize do # ロックする
#       empty_cond.wait_while { buf.empty? } # 配列が空である間はロックを開放して待つ
#       print buf.shift # 配列が空でなくなった後ロックを取得してこの行を実行
#     end # ロックを開放
#   end
# end

# # producer
# args = [423,23523,6354775]
# while line = args.pop#ARGF.gets
#   buf.synchronize do # ロックする
#     buf.push(line) # 配列を変更(追加)
#     empty_cond.signal # 配列に要素が追加されたことを条件変数を通して通知
#   end # ここでロックを開放
# end

# sleep 1.0