require 'wires'
# require_relative 'wires-devel'

require 'minitest/autorun'
require 'minitest/spec'
# require 'turn'
# Turn.config.format  = :outline
# Turn.config.natural = true
# Turn.config.trace   = 5


describe Wires::Channel do
  
  # Clean out channel list between each test
  def setup
    Wires::Channel.class_variable_set('@@channel_list', Set.new([Channel('*')]))
  end
  
  it "takes exactly one argument" do
    lambda {Wires::Channel.new}.must_raise ArgumentError
    for i in 2..20
      lambda {Wires::Channel.new(*Array(i,'arg'))}
        .must_raise ArgumentError
    end
  end
  
  it "copies exactly its one argument into Channel#name" do
    for name in ['name', :name, /regex/, Wires::Event, Wires::Event.new, Object]
      Wires::Channel.new(name).name.must_equal name
    end
  end
  
  it "creates exactly one unique instance for each unique name" do
    past_channels = []
    for name in ['event', :event, /regex/, Wires::Event, Wires::Event.new, Object]
      past_channels << (c = Channel(name))
      Channel(name).must_be_same_as c
    end
    past_channels.must_equal past_channels.uniq
  end
  
  it "can be created with the alias Channel(arg)" do
    Wires::Channel.new('new').must_equal Channel('new')
  end
  
  # it "registers itself into @@channel_hash" do
  #   chanlist = Channel.class_variable_get('@@channel_hash').values
  #   newchan = Channel('new_channel')
  #   chanlist = Channel.class_variable_get('@@channel_hash').values - chanlist
  #   chanlist.must_equal [newchan]
  # end
  
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
  
  it "can give relevant_channels for a list of channels, too" do
    dogobj = Object.new; def dogobj.channel_name; :dog; end
    catobj = Object.new; def catobj.channel_name; /c.t/; end
    catstrobj = Object.new; def catstrobj.to_s; 'cat'; end
    otherobj = Object.new; def otherobj.channel_name; 'other'; end
    otherstrobj = Object.new; def otherstrobj.to_s; 'other'; end
    relevant = ['*', "dog", :cat, /d./, dogobj, catobj, catstrobj]
    irrelevant = ["frog", /unrelated [Rr]egexp/, ]
    (relevant+irrelevant).each { |x| Wires::Channel.new(x) }
    
    r_list = Wires::Channel.new([:dog,'cat',:cat])
                           .relevant_channels
                           .map {|c| c.name}
                           
    relevant.each{|r| r_list.must_include r}
    r_list.size.must_equal relevant.size
  end
  
  
end

