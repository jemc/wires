$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end

# Set up some events for testing
class CoolEvent       < Wires::Event;     end
class MyFavoriteEvent < CoolEvent; end

describe Wires::Event do
  
  # it "can be compared directly with a codestring or symbol (bidirectional)" do
  #   Wires::Event.must_equal    'event'
  #   CoolEvent.must_equal       'cool'
  #   MyFavoriteEvent.must_equal 'my_favorite'
  #   Wires::Event.must_equal    :event
  #   CoolEvent.must_equal       :cool
  #   MyFavoriteEvent.must_equal :my_favorite
  #   'event'.must_equal          Wires::Event
  #   'cool'.must_equal           CoolEvent
  #   'my_favorite'.must_equal    MyFavoriteEvent
  #   :event.must_equal           Wires::Event
  #   :cool.must_equal            CoolEvent
  #   :my_favorite.must_equal     MyFavoriteEvent
  # end
  
  # it "can check inheritance with a codestring or symbol (bidirectional)" do
  #   CoolEvent.must_be        :<=, :event
  #   CoolEvent.must_be        :<,  :event
  #   CoolEvent.must_be        :>,  :my_favorite
  #   CoolEvent.must_be        :>=, :my_favorite
        
  #   :event.must_be           :<=, Wires::Event
  #   :event.must_be           :>=, Wires::Event
  #   :event.wont_be           :<,  Wires::Event
  #   :event.wont_be           :>,  Wires::Event
  #   :cool.must_be            :<=, Wires::Event
  #   :cool.wont_be            :>=, Wires::Event
  #   :cool.must_be            :<,  Wires::Event
  #   :cool.wont_be            :>,  Wires::Event
  #   :my_favorite.must_be     :<=, Wires::Event
  #   :my_favorite.wont_be     :>=, Wires::Event
  #   :my_favorite.must_be     :<,  Wires::Event
  #   :my_favorite.wont_be     :>,  Wires::Event
  #   :event.wont_be           :<=, CoolEvent
  #   :event.must_be           :>=, CoolEvent
  #   :event.wont_be           :<,  CoolEvent
  #   :event.must_be           :>,  CoolEvent
  #   :cool.must_be            :<=, CoolEvent
  #   :cool.must_be            :>=, CoolEvent
  #   :cool.wont_be            :<,  CoolEvent
  #   :cool.wont_be            :>,  CoolEvent
  #   :my_favorite.must_be     :<=, CoolEvent
  #   :my_favorite.wont_be     :>=, CoolEvent
  #   :my_favorite.must_be     :<,  CoolEvent
  #   :my_favorite.wont_be     :>,  CoolEvent
  #   :event.wont_be           :<=, MyFavoriteEvent
  #   :event.must_be           :>=, MyFavoriteEvent
  #   :event.wont_be           :<,  MyFavoriteEvent
  #   :event.must_be           :>,  MyFavoriteEvent
  #   :cool.wont_be            :<=, MyFavoriteEvent
  #   :cool.must_be            :>=, MyFavoriteEvent
  #   :cool.wont_be            :<,  MyFavoriteEvent
  #   :cool.must_be            :>,  MyFavoriteEvent
  #   :my_favorite.must_be     :<=, MyFavoriteEvent
  #   :my_favorite.must_be     :>=, MyFavoriteEvent
  #   :my_favorite.wont_be     :<,  MyFavoriteEvent
  #   :my_favorite.wont_be     :>,  MyFavoriteEvent
  # end
  
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
    proc{cool.kwargs[:other] = 2}.must_raise RuntimeError
    
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
  
  it "can create a new event from specially formatted input" do
    e_args = [55, 'blah', dog:14, cow:'moo']
    args = e_args[0...-1]
    kwargs = e_args[-1]
    
    e = Wires::Event.new_from Wires::Event=>[*e_args]
    e.must_be_instance_of Wires::Event
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal nil
    
    e = Wires::Event.new_from :symbol=>[*e_args]
    e.must_be_instance_of Wires::Event
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal :symbol
    
    e = Wires::Event.new_from CoolEvent=>[*e_args]
    e.must_be_instance_of CoolEvent
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal nil
    
    e = Wires::Event.new_from MyFavoriteEvent=>[*e_args]
    e.must_be_instance_of MyFavoriteEvent
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.event_type.must_equal nil
    
    e = Wires::Event.new_from 'some_string'=>[*e_args]
    e.must_be_nil
    
    e = Wires::Event.new_from Object=>[*e_args]
    e.must_be_nil
  end
  
end
