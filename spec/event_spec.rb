$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end

# Set up some events for testing
class CoolEvent       < Wires::Event; end
class MyFavoriteEvent < CoolEvent;    end

describe Wires::Event do
  
  it "automatically creates attributes, getters, but not setters "\
     "from the initial arguments passed to the constructor" do
    cool = CoolEvent.new(13, 24, 10, 
                         dogname:'Grover', 
                         fishscales:7096) \
                           {'even a passed codeblock gets internalized!'}
    
    cool.args.must_equal [13, 24, 10]
    proc{cool.args << 6}.must_raise RuntimeError
    
    cool.dogname.must_equal 'Grover'
    cool.fishscales.must_equal 7096
    
    checkhash = Hash.new
    checkhash[:dogname] = 'Grover'
    checkhash[:fishscales] = 7096
    cool.kwargs.must_equal checkhash
    
    assert cool.codeblock.is_a? Proc
    cool.codeblock.call.must_equal 'even a passed codeblock gets internalized!'
  end
  
  it "uses the specified value for args when :args is a kwarg,"\
     " with a crucial difference being that the specified object"\
     " doesn't get duped or frozen (because it could be anything)." do
    cool = CoolEvent.new(13, 24, 10)
    
    cool.args.must_equal [13, 24, 10]
    proc{cool.args << 6}.must_raise RuntimeError
    cool.args.must_equal [13, 24, 10]
    
    cool = CoolEvent.new(6, 5, 7, args:[13, 24, 10])
    cool.args.must_equal [13, 24, 10]
    cool.args << 6  # wont_raise RuntimeError
    cool.args.must_equal [13, 24, 10, 6]
  end
  
  it "can create an array of events from specially formatted input" do
    e_args = [55, 'blah', dog:14, cow:'moo']
    args = e_args[0...-1]
    kwargs = e_args[-1]
    
    e = Wires::Event.new_from(Wires::Event=>[*e_args]).first
    e.class.must_equal Wires::Event
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal nil
    
    e = Wires::Event.new_from(:symbol=>[*e_args]).first
    e.class.must_equal Wires::Event
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal :symbol
    
    e = Wires::Event.new_from(CoolEvent=>[*e_args]).first
    e.class.must_equal CoolEvent
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal CoolEvent
    
    e = Wires::Event.new_from(MyFavoriteEvent=>[*e_args]).first
    e.class.must_equal MyFavoriteEvent
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal MyFavoriteEvent
    
    e = Wires::Event.new_from('some_string'=>[*e_args]).first
    e.must_be_nil
    
    e = Wires::Event.new_from(Object=>[*e_args]).first
    e.must_be_nil
    
    e = Wires::Event.new_from(Wires::Event).first
    e.class.must_equal Wires::Event
    e.args.must_equal Array.new
    e.kwargs.must_equal Hash.new
    e.event_type.must_equal nil
    
    e = Wires::Event.new_from(:symbowl).first
    e.class.must_equal Wires::Event
    e.args.must_equal Array.new
    e.kwargs.must_equal Hash.new
    e.event_type.must_equal :symbowl
    
    e = Wires::Event.new_from(CoolEvent).first
    e.class.must_equal CoolEvent
    e.args.must_equal Array.new
    e.kwargs.must_equal Hash.new
    e.event_type.must_equal CoolEvent
    
    proc{e = CoolEvent.new_from(CoolEvent).first}.must_raise NoMethodError
    
  end
  
  it "can perform event pattern matching with =~" do
    
    table = {
      true => [
      # Listening for                       will receive
        [Wires::Event,                      Wires::Event],
        [:dog,                              :dog],
        [Wires::Event,                      :dog],
        [{Wires::Event=>[55]},              {Wires::Event=>[55]}],
        [{Wires::Event=>[55]},              {Wires::Event=>[55,66]}],
        [{Wires::Event=>[55,66]},           {Wires::Event=>[55,66]}],
        [{Wires::Event=>[55,66]},           {Wires::Event=>[55,66,77]}],
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[arg1:32]}],
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[55, arg1:32]}],
      ],
      
      false => [
      # Listening for                       won't receive
        [:dog,                              :cat],
        [:dog,                              Wires::Event],
        [{Wires::Event=>[55]},              {Wires::Event=>[66,55]}],
        [{Wires::Event=>[55,66]},           {Wires::Event=>[55]}],
        [{Wires::Event=>[55,66,77]},        {Wires::Event=>[55,66]}],
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[]}],
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[32]}],
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[arg1:33]}],
      ]
    }
    
    for k,set in table
      for pair in set
        a,b = pair.map { |x| Wires::Event.new_from x }
        
        a.count.must_be :>=, 1, "\nBad listen pattern: #{a}"
        b.count.must_equal   1, "\nBad fire pattern: #{b}"
        a.map do |x|
          x =~ b.first
        end.any?.must_equal k, "\nBad pair: #{pair}"
      end
    end
    
  end
  
end
