$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end


describe Wires::Channel do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.router.clear_channels
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
    chan.instance_variable_get('@target_list').count.must_equal 0
    assert_equal (chan.register :event, &proc), proc
    chan.instance_variable_get('@target_list').count.must_equal 1
  end
  
  it "can unstore event/proc associations from @target_list with #unregister" do
    proc = Proc.new{nil}
    chan = Wires::Channel.new('new')
    chan.instance_variable_get('@target_list').count.must_equal 0
    assert_equal (chan.register :event, &proc), proc
    chan.instance_variable_get('@target_list').count.must_equal 1
    assert_equal (chan.unregister :event, &proc), true
    chan.instance_variable_get('@target_list').count.must_equal 0
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
  
  it "correctly routes activity on one channel to relevant receivers" do
    chan=Wires::Channel.new('relevant')
    
    relevant   = [chan, 
                  Wires::Channel.new(/^rel.van(t|ce)/), 
                  Wires::Channel.new('*')]
    
    irrelevant = [Wires::Channel.new('irrelevant'), 
                  Wires::Channel.new(:relevant), 
                  Wires::Channel.new(/mal.volen(t|ce)/)]
    
    for c in chan.receivers
      relevant.must_include c end
    for c in relevant
      chan.receivers.must_include c end
    (chan.receivers&irrelevant).must_be_empty
  end
  
  # it "can give receivers for a list of channels, too" do
  #   dogobj = Object.new; def dogobj.channel_name; :dog; end
  #   catobj = Object.new; def catobj.channel_name; /c.t/; end
  #   catstrobj = Object.new; def catstrobj.to_s; 'cat'; end
  #   otherobj = Object.new; def otherobj.channel_name; 'other'; end
  #   otherstrobj = Object.new; def otherstrobj.to_s; 'other'; end
  #   relevant = ['*', "dog", :cat, /d./, dogobj, catobj, catstrobj]
  #   irrelevant = ["frog", /unrelated [Rr]egexp/, otherstrobj]
  #   (relevant+irrelevant).each { |x| Wires::Channel.new(x) }
    
  #   r_list = Wires::Channel.new([:dog,'cat',:cat])
  #                          .receivers
  #                          .map {|c| c.name}
                           
  #   relevant.each{|r| r_list.must_include r}
  #   r_list.size.must_equal relevant.size
  # end
  
  # it "updates relevant_channels when an object evaluates differently"
  
  it "can call hooks before and after fire method" do
    
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
    
    Wires::Channel.instance_variable_get(:@before_fire).wont_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).wont_be_empty
    
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
    fire SomeEvent, 'Wires::Channel_A'
    hook_val.must_equal 'E'
    
    Wires::Channel.instance_variable_get(:@before_fire).wont_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).wont_be_empty
    
    Wires::Channel.clear_hooks(:@before_fire)
    Wires::Channel.clear_hooks(:@after_fire)
    
    Wires::Channel.instance_variable_get(:@before_fire).must_be_empty
    Wires::Channel.instance_variable_get(:@after_fire).must_be_empty
    
  end
  
end
