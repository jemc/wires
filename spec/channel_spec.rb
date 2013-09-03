$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
# begin require 'jemc/reporter'; rescue LoadError; end


describe Wires::Channel do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.class_variable_set('@@channel_list', 
                                      Set.new([Wires::Channel.new('*')]))
  end
  
  it "takes exactly one argument" do
    lambda {Wires::Channel.new}.must_raise ArgumentError
    for i in 2..20
      lambda {Wires::Channel.new(*Array(i,'arg'))}
        .must_raise ArgumentError
    end
  end
  
  it "copies exactly its one argument into Wires::Channel#name" do
    for name in ['name', :name, /regex/, Wires::Event, Wires::Event.new, Object]
      Wires::Channel.new(name).name.must_equal name
    end
  end
  
  it "creates exactly one unique instance for each unique name" do
    past_channels = []
    for name in ['event', :event, /regex/, Wires::Event, Wires::Event.new, Object]
      past_channels << (c = Wires::Channel.new(name))
      Wires::Channel.new(name).must_be_same_as c
    end
    past_channels.must_equal past_channels.uniq
  end
  
  it "assigns new unique object IDs in a threadsafe way" do
    for n in 1..5
      threads = []
      channels = []
      proc = Proc.new {channels<<Wires::Channel.new(n)}
      for m in 0..100
        threads[m] = Thread.new(&proc)
      end
      threads.each{|x| x.join}
      channels.uniq.size.must_equal 1
    end
  end
  
  it "can store event/proc associations in @target_list with #register" do
    proc = Proc.new{nil}
    chan = Wires::Channel.new('new')
    list = chan.instance_variable_get('@target_list').to_a
    assert_equal (chan.register :event, &proc), proc
    list = chan.instance_variable_get('@target_list').to_a - list
    list.size.must_equal 1
  end
  
  it "can unstore event/proc associations from @target_list with #unregister" do
    proc = Proc.new{nil}
    chan = Wires::Channel.new('new')
    list = chan.instance_variable_get('@target_list').to_a
    assert_equal (chan.register :event, &proc), proc
    assert_equal (chan.unregister :event, &proc), true
    list.must_equal chan.instance_variable_get('@target_list').to_a
  end
  
  it "can unstore all occurrences of a proc in @target_list with #unregister" do
    proc = Proc.new{nil}
    chan = Wires::Channel.new('new')
    list = chan.instance_variable_get('@target_list').to_a
    assert_equal (chan.register :event, &proc), proc
    assert_equal (chan.unregister &proc), true
    list.must_equal chan.instance_variable_get('@target_list').to_a
  end
  
  it "raises SyntaxError when proc in register(event, proc) isn't a Proc" do
    chan = Wires::Channel.new('new')
    for not_proc in [nil, :symbol, 'string', Array.new, Hash.new]
      lambda {chan.register(:event, not_proc)}.must_raise SyntaxError
    end
    lambda {chan.register(:event, Proc.new{nil})}
  end
  
  it "correctly routes activity on one channel to relevant channels" do
    chan=Wires::Channel.new('relevant')
    
    relevant   = [chan, 
                  Wires::Channel.new(:relevant), 
                  Wires::Channel.new(/^rel.van(t|ce)/), 
                  Wires::Channel.new('*')]
    
    irrelevant = [Wires::Channel.new('irrelevant'), 
                  Wires::Channel.new(/mal.vole(t|ce)/)]
    
    for c in chan.relevant_channels
      relevant.must_include c end
    for c in relevant
      chan.relevant_channels.must_include c end
    (chan.relevant_channels&irrelevant).must_be_empty
  end
  
  it "can give relevant_channels for a list of channels, too" do
    dogobj = Object.new; def dogobj.channel_name; :dog; end
    catobj = Object.new; def catobj.channel_name; /c.t/; end
    catstrobj = Object.new; def catstrobj.to_s; 'cat'; end
    otherobj = Object.new; def otherobj.channel_name; 'other'; end
    otherstrobj = Object.new; def otherstrobj.to_s; 'other'; end
    relevant = ['*', "dog", :cat, /d./, dogobj, catobj, catstrobj]
    irrelevant = ["frog", /unrelated [Rr]egexp/, otherstrobj]
    (relevant+irrelevant).each { |x| Wires::Channel.new(x) }
    
    r_list = Wires::Channel.new([:dog,'cat',:cat])
                           .relevant_channels
                           .map {|c| c.name}
                           
    relevant.each{|r| r_list.must_include r}
    r_list.size.must_equal relevant.size
  end
  
  it "can call hooks before and after fire method,"\
     "which aren't retained when Hub is killed by default" do
    
    class SomeEvent < Wires::Event; end
    
    hook_val = 'A'
    Wires::Channel.before_fire { hook_val.must_equal 'A'; hook_val = 'B' }
    Wires::Channel.before_fire { hook_val.must_equal 'B'; hook_val = 'C' }
    Wires::Channel.after_fire  { hook_val.must_equal 'C'; hook_val = 'D' }
    Wires::Channel.after_fire  { hook_val.must_equal 'D'; hook_val = 'E' }
    save_proc = Wires::Channel.after_fire do |event,chan|
      assert event.is_a? Wires::Event
      assert chan.is_a? Wires::Channel
    end
    
    Wires::Channel.clear_hooks(:@before_fire)
    Wires::Channel.clear_hooks(:@after_fire)
    
    Wires::Channel.instance_variable_get(:@before_fire).must_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).must_be_empty
    
    hook_val = 'A'
    Wires::Channel.before_fire { hook_val.must_equal 'A'; hook_val = 'B' }
    Wires::Channel.before_fire { hook_val.must_equal 'B'; hook_val = 'C' }
    Wires::Channel.after_fire  { hook_val.must_equal 'C'; hook_val = 'D' }
    Wires::Channel.after_fire  { hook_val.must_equal 'D'; hook_val = 'E' }
    save_proc = Wires::Channel.after_fire do |event,chan|
      assert event.is_a? Wires::Event
      assert chan.is_a? Wires::Channel
    end
    
    
    assert_instance_of Proc, save_proc
    hook_val.must_equal 'A'
    Wires::Hub.run
    fire SomeEvent, 'Wires::Channel_A'
    Wires::Hub.kill
    hook_val.must_equal 'E'
    
    hook_val = 'A'
    hook_val.must_equal 'A'
    Wires::Hub.run
    fire SomeEvent, 'Wires::Channel_A'
    Wires::Hub.kill
    hook_val.must_equal 'A'
    
    
    Wires::Channel.instance_variable_get(:@before_fire).must_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).must_be_empty
    
    hook_val = 'A'
    Wires::Channel.before_fire(true){ hook_val.must_equal 'A'; hook_val = 'B' }
    Wires::Channel.before_fire(true){ hook_val.must_equal 'B'; hook_val = 'C' }
    Wires::Channel.after_fire (true){ hook_val.must_equal 'C'; hook_val = 'D' }
    Wires::Channel.after_fire (true){ hook_val.must_equal 'D'; hook_val = 'E' }
    save_proc = Wires::Channel.before_fire do |event,chan|
      assert event.is_a? Wires::Event
      assert chan.is_a? Wires::Channel
    end
    assert_instance_of Proc, save_proc
    hook_val.must_equal 'A'
    Wires::Hub.run
    fire SomeEvent, 'Wires::Channel_A'
    Wires::Hub.kill
    hook_val.must_equal 'E'
    
    hook_val = 'A'
    hook_val.must_equal 'A'
    Wires::Hub.run
    fire SomeEvent, 'Wires::Channel_A'
    Wires::Hub.kill
    hook_val.must_equal 'E'
    
    list = Wires::Channel.instance_variable_get(:@after_fire)
    Wires::Channel.remove_hook(:@after_fire, &save_proc)
    Wires::Channel.instance_variable_get(:@after_fire)
      .must_equal (list - [save_proc])
    Wires::Channel.add_hook(:@after_fire, &save_proc)
    (Wires::Channel.instance_variable_get(:@after_fire) - [save_proc])
      .must_equal list
    
    Wires::Channel.instance_variable_get(:@before_fire).wont_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).wont_be_empty
    
    Wires::Channel.clear_hooks(:@before_fire)
    Wires::Channel.clear_hooks(:@after_fire)
    
    Wires::Channel.instance_variable_get(:@before_fire).wont_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).wont_be_empty
    
    Wires::Channel.clear_hooks(:@before_fire, true)
    Wires::Channel.clear_hooks(:@after_fire,  true)
    
    Wires::Channel.instance_variable_get(:@before_fire).must_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).must_be_empty
    
  end
  
end

