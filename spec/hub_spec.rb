$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


# class MyEvent      < Wires::Event; end
# class MyOtherEvent < Wires::Event; end

describe Wires::Hub do
  
  it "can handle events called from other events" do
    
    count = 0
    
    on MyEvent, 'Wires::Hub_A' do |e|
      count.must_equal e.i
      count += 1
    end
    
    fire MyEvent.new(i:0), 'Wires::Hub_A'
    
  end
  
  it "can block until the events are fired with fire_and_wait" do
    
    count = 0
    
    on MyEvent, 'Wires::Hub_B' do |e|
      count.must_equal e.i
      count += 1
      fire_and_wait([MyEvent=>[i:(e.i+1)]], 'Wires::Hub_B') if e.i < 9
      count.must_equal 10
    end
    
    fire_and_wait [MyEvent=>[i:0]], 'Wires::Hub_B'
    count.must_equal 10
    
  end
  
  it "allows the user to set an arbitrary maximum number of children"\
     " and temporarily neglects to spawn all further threads" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, proc{sleep 0.1 until done_flag}, false]
    
    Wires::Hub.max_children = 3
    Wires::Hub.max_children.must_equal 3
    Wires::Hub.max_children.times do
      Wires::Hub.spawn(*spargs).must_be_instance_of Thread
    end
    Wires::Hub.count_neglected.must_equal 0
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.count_neglected.must_equal 1
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.count_neglected.must_equal 2
    Wires::Hub.clear_neglected
    Wires::Hub.count_neglected.must_equal 0
    Wires::Hub.spawn(*spargs).must_equal false
    Wires::Hub.count_neglected.must_equal 1
    
    done_flag = true
    Thread.pass
    
    Wires::Hub.max_children = nil
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that raise a ThreadError on creation;"\
     " that is, when there are too many threads for the OS to handle" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, Proc.new{sleep 0.1 until done_flag}, false]
    
    count = 0
    while Wires::Hub.spawn(*spargs)
      count += 1
      Wires::Hub.count_neglected.must_equal 0
    end
    
    Wires::Hub.count_neglected.must_equal 1
    Wires::Hub.spawn(*spargs)
    Wires::Hub.count_neglected.must_equal 2
    
    done_flag = true
    sleep 0.15
    Wires::Hub.count_neglected.must_equal 0
    
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that try to spawn as threads"\
     " during Wires::Hub.hold, but allows procs to spawn in place" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    var = 'before'
    spargs = [nil, nil, proc{var = 'after'}, false]
    
    Wires::Hub.count_neglected.must_equal 0
    
    Wires::Hub.hold do
      Wires::Hub.count_neglected.must_equal 0
      Wires::Hub.spawn(*spargs).must_equal false
      Wires::Hub.count_neglected.must_equal 1
      var.must_equal 'before'
    end
    Wires::Hub.join_children
    
    var.must_equal 'after'
    Wires::Hub.count_neglected.must_equal 0
    
    var = 'before'
    Wires::Hub.hold do
      Wires::Hub.count_neglected.must_equal 0
      Wires::Hub.spawn(*spargs) .must_equal false
      Wires::Hub.count_neglected.must_equal 1
      var.must_equal 'before'
    end
    Wires::Hub.join_children
    
    $stderr = stderr_save # Restore $stderr
  end
  
  it "logs neglects to $stderr by default," \
     "but allows you to specify a different action if desired" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    spargs = [nil, nil, proc{nil}, false]
    
    Wires::Hub.hold do
      Wires::Hub.spawn(*spargs).must_equal false
      $stderr.size.must_be :>, 0
      $stderr = StringIO.new
      $stderr.size.must_be :==,0
    end
    
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    
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
    
    Wires::Hub.hold do
      Wires::Hub.spawn(*spargs).must_equal false
      $stderr.size.must_be :==, 0
      something_happened.must_equal true
      count.must_be :>, 0
    end
    
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :==, 0
    
    Wires::Hub.reset_neglect_procs
    $stderr = stderr_save # Restore $stderr
  end
  
  
  it "passes the correct parameters to each spawned proc" do
    it_happened = false
    on MyEvent, 'Wires::Hub_Params' do |event, ch_string|
      event.must_be_instance_of MyEvent
      ch_string.must_equal 'Wires::Hub_Params'
      it_happened = true
    end
    
    fire MyEvent, 'Wires::Hub_Params'
    Wires::Hub.join_children
    it_happened.must_equal true
  end
  
  
  it "lets you set a custom event handler exception handler" do
    
    on MyEvent, 'Wires::Hub_Exc' do |e|
      e.method_that_isnt_defined
    end
    
    count = 0
    Wires::Hub.on_handler_exception do |exc, event, ch_string|
      
      exc.backtrace.wont_be_nil
      exc.fire_backtrace.wont_be_nil
      event.must_be_instance_of MyEvent
      ch_string.must_equal 'Wires::Hub_Exc'
      count += 1
    end
    
    fire_and_wait MyEvent, 'Wires::Hub_Exc'
    fire          MyEvent, 'Wires::Hub_Exc'
    
    Wires::Hub.join_children
    Wires::Hub.reset_handler_exception_proc
    
    count.must_equal 2
    
  end
  
end
