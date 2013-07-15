require 'wires'

require 'minitest/autorun'
require 'minitest/spec'

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
  
  it "allows the user to set an arbitrary maximum number of child_threads"\
     " and temporarily neglects to spawn all further threads" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, proc{sleep 0.1 until done_flag}, false]
    
    Hub.max_child_threads = 3
    Hub.max_child_threads.must_equal 3
    Hub.run
    Hub.max_child_threads.times do
      Hub.spawn(*spargs).must_be_instance_of Thread
    end
    Hub.number_neglected.must_equal 0
    Hub.spawn(*spargs).must_equal false
    Hub.number_neglected.must_equal 1
    Hub.spawn(*spargs).must_equal false
    Hub.number_neglected.must_equal 2
    Hub.purge_neglected
    Hub.number_neglected.must_equal 0
    Hub.spawn(*spargs).must_equal false
    Hub.number_neglected.must_equal 1
    
    done_flag = true
    Thread.pass
    # Hub.number_neglected.must_equal 0
    
    Hub.kill
    Hub.max_child_threads = nil
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that raise a ThreadError on creation;"\
     " that is, when there are too many threads for the OS to handle" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, proc{sleep 0.1 until done_flag}, false]
    Hub.run
    
    count = 0
    while Hub.spawn(*spargs)
      count += 1
      Hub.number_neglected.must_equal 0
    end
    
    Hub.number_neglected.must_equal 1
    Hub.spawn(*spargs)
    Hub.number_neglected.must_equal 2
    
    done_flag = true
    sleep 0.15
    Hub.number_neglected.must_equal 0
    
    Hub.kill
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that try to spawn before Hub is running" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    var = 'before'
    spargs = [nil, nil, proc{var = 'after'}, false]
    
    Hub.number_neglected.must_equal 0
    Hub.spawn(*spargs).must_equal false
    Hub.number_neglected.must_equal 1
    Hub.run
    var.must_equal 'after'
    Hub.number_neglected.must_equal 0
    
    Hub.kill
    $stderr = stderr_save # Restore $stderr
  end
  
  it "logs neglects to $stderr by default," \
     "but allows you to specify a different action if desired" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    spargs = [nil, nil, proc{nil}, false]
    
    Hub.spawn(*spargs).must_equal false
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    $stderr.size.must_be :==,0
    
    Hub.run
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    Hub.kill
    
    count = 0
    something_happened = false
    Hub.on_neglect do |args|
      args.size.must_equal 4
      count += 1
      something_happened = true
    end
    Hub.on_neglect_done do |args|
      args.size.must_equal 4
      count -= 1
    end
    
    Hub.spawn(*spargs).must_equal false
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :>, 0
    
    Hub.run
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :==, 0
    Hub.kill
    
    Hub.send(:class_init) # Reset neglect procs
    $stderr = stderr_save # Restore $stderr
  end
  
end