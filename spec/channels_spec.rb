require 'wires'

require 'minitest/spec'
require 'minitest/autorun'

describe Channel do
  
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
    Channel.class_variable_set('@@channel_list', Set.new)
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
  
  # it "gives a list of channels that would receive fire as relevant_channels" do
  #   class ThingEvent < Event; end
  #   class OtherEvent < ThingEvent; end
  #   matches = [Channel('*'), Channel(/th.[nm]g$/), Channel('thing'), 
  #              Channel(ThingEvent), Channel(ThingEvent.new), 
  #              Channel(:event), Channel(Event), Channel(Event.new)]
  #   notches = [Channel(:other), Channel(OtherEvent), Channel(OtherEvent.new),
  #              Channel(:arbitrary), Channel(/therem.[nm]$/)]
  #   relevant = Channel('thing').relevant_channels
    
  #   for m in matches
  #     relevant.must_include m
  #   end
  #   for m in relevant
  #     matches.must_include m
  #   end
  #   (relevant&notches).must_be_empty
  # end
end

# class ThingEvent < Event; end
# class OtherEvent < ThingEvent; end

# matches = [Channel('*'), Channel(/th.[nm]g$/), Channel('thing'), 
#            Channel(ThingEvent), Channel(ThingEvent.new), 
#            Channel(:event), Channel(Event), Channel(Event.new)]
# notches = [Channel(:other), Channel(OtherEvent), Channel(OtherEvent.new),
#            Channel(:arbitrary), Channel(/therem.[nm]$/)]
# relevant = Channel('thing').relevant_channels.to_a

# # p matches.map{|x| x.name}
# # p matches
# # p relevant.map{|x| x.name}
# p (relevant&matches)==relevant
# p (relevant&notches).empty?
