$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end

require 'pry-rescue/minitest'
require 'stringio'


describe Wires::Hub do
  
  it "can handle events called from other events" do
    
    count = 0
    
    on :event, self do |e|
      count.must_equal e.i
      count += 1
    end
    
    fire Wires::Event.new(i:0), self
    
  end
  
  it "can block until the events are fired with fire!" do
    
    count = 0
    
    on :event, self do |e|
      count.must_equal e.i
      count += 1
      fire!([:event=>[i:(e.i+1)]], self) if e.i < 9
      count.must_equal 10
    end
    
    fire! [:event=>[i:0]], self
    count.must_equal 10
    
  end
  
  it "allows the user to set an arbitrary maximum number of children"\
     " and temporarily neglects to spawn all further threads" do
    stderr_save, $stderr = $stderr, ::StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, Proc.new{sleep 0.1 until done_flag}, false, true]
    
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
    Wires::Hub.join_children
    
    Wires::Hub.max_children = nil
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that raise a ThreadError on creation;"\
     " that is, when there are too many threads for the OS to handle" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    done_flag = false
    spargs = [nil, nil, Proc.new{sleep 0.1 until done_flag}, false, true]
    
    count = 0
    while Wires::Hub.spawn(*spargs)
      count += 1
      Wires::Hub.count_neglected.must_equal 0
    end
    
    Wires::Hub.count_neglected.must_equal 1
    Wires::Hub.spawn(*spargs)
    Wires::Hub.count_neglected.must_equal 2
    
    done_flag = true
    Wires::Hub.join_children
    Wires::Hub.count_neglected.must_equal 0
    
    $stderr = stderr_save # Restore $stderr
  end
  
  it "temporarily neglects procs that try to spawn as threads"\
     " during Wires::Hub.hold, but allows procs to spawn in place" do
    stderr_save, $stderr = $stderr, StringIO.new # temporarily mute $stderr
    var = 'before'
    spargs = [nil, nil, Proc.new{var = 'after'}, false, true]
    
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
    spargs = [nil, nil, Proc.new{nil}, false, true]
    
    Wires::Hub.hold do
      Wires::Hub.spawn(*spargs).must_equal false
      $stderr.size.must_be :>, 0
      $stderr = StringIO.new
      $stderr.size.must_be :==,0
    end
    Wires::Hub.join_children
    
    $stderr.size.must_be :>, 0
    $stderr = StringIO.new
    
    count = 0
    something_happened = false
    Wires::Hub.on_neglect do |*args|
      args.size.must_equal 5
      count += 1
      something_happened = true
    end
    Wires::Hub.on_neglect_done do |*args|
      args.size.must_equal 5
      count -= 1
    end
    
    Wires::Hub.hold do
      Wires::Hub.spawn(*spargs).must_equal false
      $stderr.size.must_be :==, 0
      something_happened.must_equal true
      count.must_be :>, 0
    end
    Wires::Hub.join_children
    
    $stderr.size.must_be :==, 0
    something_happened.must_equal true
    count.must_be :==, 0
    
    Wires::Hub.reset_neglect_procs
    $stderr = stderr_save # Restore $stderr
  end
  
  
  it "passes the correct parameters to each spawned proc" do
    it_happened = false
    on :event, self do |event, ch_string|
      event.must_be_instance_of Wires::Event
      ch_string.must_equal self
      it_happened = true
    end
    
    fire :event, self
    Wires::Hub.join_children
    it_happened.must_equal true
  end
  
  
  it "lets you set a custom event handler exception handler" do
    
    on :event, self do |e|
      e.method_that_isnt_defined
    end
    
    count = 0
    Wires::Hub.on_handler_exception do |exc, event, ch_string|
      
      exc.backtrace.wont_be_nil
      exc.fire_backtrace.wont_be_nil
      event.must_be_instance_of Wires::Event
      ch_string.must_equal self
      count += 1
    end
    
    fire! :event, self
    fire  :event, self
    
    Wires::Hub.join_children
    Wires::Hub.reset_handler_exception_proc
    
    count.must_equal 2
    
  end
  
end
