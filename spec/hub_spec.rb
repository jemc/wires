$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


class MyEvent      < Wires::Event; end
class MyOtherEvent < Wires::Event; end

describe Wires::Hub do
  
  # it "allows the setting of custom grains"  # TODO
  
  it "can be run and killed multiple times" do
    
    initial_threads = Thread.list
    
    Wires::Hub.dead?.must_equal true
    Wires::Hub.state.must_equal :dead
    Wires::Hub.state.must_equal :dead
    
    Wires::Hub.run
    Wires::Hub.kill
    
    Thread.list.must_equal initial_threads
    
    Wires::Hub.run
    Wires::Hub.kill
    
    Thread.list.must_equal initial_threads
    
    Wires::Hub.dead?.must_equal true
    Wires::Hub.state.must_equal :dead
    
    Wires::Hub.run
    
    Wires::Hub.alive?.must_equal true
    Wires::Hub.state.must_equal :alive
    
    Wires::Hub.kill
    Wires::Hub.run
    Wires::Hub.kill
    
    Wires::Hub.dead?.must_equal true
    Wires::Hub.state.must_equal :dead
    
    Thread.list.must_equal initial_threads
    
  end
  
  it "can call hooks before and after run and kill" do
    
    hook_val = 'A'
    
    Wires::Hub.before_run  { hook_val.must_equal 'A'; hook_val = 'B' }
    Wires::Hub.before_run  { hook_val.must_equal 'B'; hook_val = 'C' }
    Wires::Hub.after_run   { hook_val.must_equal 'C'; hook_val = 'D' }
    Wires::Hub.after_run   { hook_val.must_equal 'D'; hook_val = 'E' }
    
    Wires::Hub.before_kill { hook_val.must_equal 'E'; hook_val = 'F' }
    Wires::Hub.before_kill { hook_val.must_equal 'F'; hook_val = 'G' }
    Wires::Hub.after_kill  { hook_val.must_equal 'G'; hook_val = 'H' }
    Wires::Hub.after_kill  { hook_val.must_equal 'H'; hook_val = 'I' }
    
    hook_val.must_equal 'A'
    Wires::Hub.run
    hook_val.must_equal 'E'
    Wires::Hub.kill
    hook_val.must_equal 'I'
    
  end
  
  it "can handle events called from other events" do
    
    count = 0
    
    on MyEvent, 'Wires::Hub_A' do |e|
      count.must_equal e.i
      count += 1
    end
    
    Wires::Hub.run
    fire MyEvent.new(i:0), 'Wires::Hub_A'
    Wires::Hub.kill
    
  end
  
  it "can block until the events are fired with fire_and_wait" do
    
    count = 0
    
    on MyEvent, 'Wires::Hub_B' do |e|
      count.must_equal e.i
      count += 1
      fire_and_wait(MyEvent.new(i:(e.i+1)), 'Wires::Hub_B') if e.i < 9
      count.must_equal 10
    end
    
    Wires::Hub.run
    fire_and_wait MyEvent.new(i:0), 'Wires::Hub_B'
    count.must_equal 10
    Wires::Hub.kill
    
  end
  
  it "allows the user to set an arbitrary maximum number of child_threads"\
     " and temporarily neglects to spawn all further threads" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, proc{sleep 0.1 until done_flag}, false]
    
    Wires::Hub.max_child_threads = 3
    Wires::Hub.max_child_threads.must_equal 3
    Wires::Hub.run
    Wires::Hub.max_child_threads.times do
      Wires::Hub.spawn(*spargs).must_be_instance_of Thread
    end
    Wires::Hub.number_neglected.must_equal 0
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.number_neglected.must_equal 1
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.number_neglected.must_equal 2
    Wires::Hub.purge_neglected
    Wires::Hub.number_neglected.must_equal 0
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.number_neglected.must_equal 1
    
    done_flag = true
    Thread.pass
    # Wires::Hub.number_neglected.must_equal 0
    
    Wires::Hub.kill
    Wires::Hub.max_child_threads = nil
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that raise a ThreadError on creation;"\
     " that is, when there are too many threads for the OS to handle" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, proc{sleep 0.1 until done_flag}, false]
    Wires::Hub.run
    
    count = 0
    while Wires::Hub.spawn(*spargs)
      count += 1
      Wires::Hub.number_neglected.must_equal 0
    end
    
    Wires::Hub.number_neglected.must_equal 1
    Wires::Hub.spawn(*spargs)
    Wires::Hub.number_neglected.must_equal 2
    
    done_flag = true
    sleep 0.15
    Wires::Hub.number_neglected.must_equal 0
    
    Wires::Hub.kill
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that try to spawn before Wires::Hub is running" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    var = 'before'
    spargs = [nil, nil, proc{var = 'after'}, false]
    
    Wires::Hub.number_neglected.must_equal 0
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.number_neglected.must_equal 1
    Wires::Hub.run
    var.must_equal 'after'
    Wires::Hub.number_neglected.must_equal 0
    
    Wires::Hub.kill
    $stderr = stderr_save # Restore $stderr
  end
  
  it "logs neglects to $stderr by default," \
     "but allows you to specify a different action if desired" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    spargs = [nil, nil, proc{nil}, false]
    
    Wires::Hub.spawn(*spargs).must_equal false
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    $stderr.size.must_be :==,0
    
    Wires::Hub.run
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    Wires::Hub.kill
    
    count = 0
    something_happened = false
    Wires::Hub.on_neglect do |*args|
      args.size.must_equal 4
      count += 1
      something_happened = true
    end
    Wires::Hub.on_neglect_done do |*args|
      args.size.must_equal 4
      count -= 1
    end
    
    Wires::Hub.spawn(*spargs).must_equal false
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :>, 0
    
    Wires::Hub.run
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :==, 0
    Wires::Hub.kill
    
    Wires::Hub.reset_neglect_procs
    $stderr = stderr_save # Restore $stderr
  end
  
  
  it "passes the correct parameters to each spawned proc" do
    it_happened = false
    on :event, 'Wires::Hub_Params' do |event, ch_string|
      event.must_be_instance_of Event
      ch_string.must_equal 'Wires::Hub_Params'
      it_happened = true
    end
    
    Wires::Hub.run
    fire :event, 'Wires::Hub_Params'
    Wires::Hub.kill
    it_happened.must_equal true
  end
  
  
  it "lets you set a custom event handler exception handler" do
    
    on MyEvent, 'Wires::Hub_Exc' do |e|
      e.method_that_isnt_defined
    end
    
    count = 0
    Wires::Hub.on_handler_exception do |exc, event, ch_string|
      # exc.backtrace.wont_be_nil
      # exc.fire_backtrace.wont_be_nil
      # event.wont_be_nil
      # ch_string.wont_be_nil
      # count += 1
    end
    Wires::Hub.run
    
    fire_and_wait :my, 'Wires::Hub_Exc'
    fire          :my, 'Wires::Hub_Exc'
    
    Wires::Hub.kill
    Wires::Hub.reset_handler_exception_proc
    
    # count.must_equal 2
    
  end
  
end
