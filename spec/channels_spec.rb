require 'wires'

require 'minitest/spec'
require 'minitest/autorun'

describe Channel do
  
  # Clean out channel list between each test
  def setup
    Channel.class_variable_set('@@channel_list', Set.new([Channel('*')]))
  end
  
  it "takes exactly one argument" do
    lambda {Channel.new}.must_raise ArgumentError
    for i in 2..20
      lambda {Channel.new(*Array(i,'arg'))}
        .must_raise ArgumentError
    end
  end
  
  it "copies exactly its one argument into Channel#name" do
    for name in ['name', :name, /regex/, Event, Event.new, Object]
      Channel.new(name).name.must_equal name
    end
  end
  
  it "creates exactly one unique instance for each unique name" do
    past_channels = []
    for name in ['event', :event, /regex/, Event, Event.new, Object]
      past_channels << (c = Channel(name))
      Channel(name).must_be_same_as c
    end
    past_channels.must_equal past_channels.uniq
  end
  
  it "can be created with the alias Channel(arg)" do
    Channel.new('new').must_equal Channel('new')
  end
  
  it "registers itself into @@channel_list" do
    chanlist = Channel.class_variable_get('@@channel_list').to_a
    newchan = Channel('new_channel')
    chanlist = Channel.class_variable_get('@@channel_list').to_a - chanlist
    chanlist.must_equal [newchan]
  end
  
  it "assigns new unique object IDs in a threadsafe way" do
    for n in 1..25
      threads = []
      channels = []
      proc = Proc.new {channels<<Channel.new(n)}
      for m in 0..100
        threads[m] = Thread.new(&proc)
      end
      threads.each{|x| x.join}
      channels.uniq.size.must_equal 1
    end
  end
  
  it "can store [event, proc] pairs in @target_list with Channel#register" do
    pair = [:event, Proc.new{nil}]
    chan = Channel('new')
    list = chan.instance_variable_get('@target_list').to_a
    chan.register(*pair)
    list = chan.instance_variable_get('@target_list').to_a - list
    list.size.must_equal 1
  end
  
  it "raises SyntaxError when proc in register(event, proc) isn't a Proc" do
    chan = Channel('new')
    for not_proc in [nil, :symbol, 'string', Array.new, Hash.new]
      lambda {chan.register(:event, not_proc)}.must_raise SyntaxError
    end
    lambda {chan.register(:event, Proc.new{nil})}
  end
  
  it "correctly routes activity on one channel to relevant channels" do
    relevant = [(chan=Channel('relevant')), Channel(:relevant), 
                      Channel(/^rel.van(t|ce)/), Channel('*')]
    irrelevant = [Channel('irrelevant'), Channel(/mal.vole(t|ce)/)]
    
    for c in chan.relevant_channels
      relevant.must_include c end
    for c in relevant
      chan.relevant_channels.must_include c end
    (chan.relevant_channels&irrelevant).must_be_empty
  end
  
end

