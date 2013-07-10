require 'wires'


include Wires

class MyEvent < Event; end
class MyOtherEvent < Event; end

describe Hub do
  
  it "can be run and killed multiple times" do
    
    initial_threads = Thread.list
    
    Hub.dead?.must_equal true
    Hub.state.must_equal :dead
    
    Hub.run
    Hub.kill
    
    Thread.list.must_equal initial_threads
    
    Hub.run
    Hub.kill
    
    Thread.list.must_equal initial_threads
    
    Hub.dead?.must_equal true
    Hub.state.must_equal :dead
    
    Hub.run
    
    Hub.alive?.must_equal true
    Hub.state.must_equal :alive
    
    Hub.kill
    Hub.run
    Hub.kill
    
    Hub.dead?.must_equal true
    Hub.state.must_equal :dead
    
    Thread.list.must_equal initial_threads
    
  end
  
  it "can call hooks before and after run and kill" do
    
    hook_val = 'A'
    
    Hub.before_run  { hook_val.must_equal 'A'; hook_val = 'B' }
    Hub.before_run  { hook_val.must_equal 'B'; hook_val = 'C' }
    Hub.after_run   { hook_val.must_equal 'C'; hook_val = 'D' }
    Hub.after_run   { hook_val.must_equal 'D'; hook_val = 'E' }
    
    Hub.before_kill { hook_val.must_equal 'E'; hook_val = 'F' }
    Hub.before_kill { hook_val.must_equal 'F'; hook_val = 'G' }
    Hub.after_kill  { hook_val.must_equal 'G'; hook_val = 'H' }
    Hub.after_kill  { hook_val.must_equal 'H'; hook_val = 'I' }
    
    hook_val.must_equal 'A'
    Hub.run
    hook_val.must_equal 'E'
    Hub.kill
    hook_val.must_equal 'I'
    
  end
  
  it "can handle events called from other events" do
    
    count = 0
    
    on MyEvent, 'Hub_A' do |e|
      count.must_equal e.i
      count += 1
    end
    
    Hub.run
    fire MyEvent.new(i:0), 'Hub_A'
    Hub.kill
    
  end
  
  it "can block until the events are fired with fire_and_wait" do
    
    count = 0
    
    on MyEvent, 'Hub_B' do |e|
      count.must_equal e.i
      count += 1
      fire_and_wait(MyEvent.new(i:(e.i+1)), 'Hub_B') if e.i < 9
      count.must_equal 10
    end
    
    Hub.run
    fire_and_wait MyEvent.new(i:0), 'Hub_B'
    count.must_equal 10
    Hub.kill
    
  end
end
