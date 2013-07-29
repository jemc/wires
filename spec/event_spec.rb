require 'wires'
# require_relative 'wires-devel'

require 'minitest/autorun'
require 'minitest/spec'
require 'turn'
Turn.config.format  = :outline
Turn.config.natural = true
Turn.config.trace   = 5


# Set up some events for testing
class CoolEvent       < Wires::Event;     end
class MyFavoriteEvent < CoolEvent; end

describe Wires::Event do
  
  it "registers itself and its subclasses in an array" do
    Wires::Event.class_variable_get(:@@registry).must_include Wires::Event
    Wires::Event.class_variable_get(:@@registry).must_include CoolEvent
    Wires::Event.class_variable_get(:@@registry).must_include MyFavoriteEvent
  end
  
  it "generates a corresponding codestring upon subclass definition" do
    Wires::Event.codestring.must_equal    'event'
    CoolEvent.codestring.must_equal       'cool'
    MyFavoriteEvent.codestring.must_equal 'my_favorite'
  end
  
  it "enforces that new subclasses must have a unique codestring" do
    proc{class My_FavoriteEvent < CoolEvent; end}.must_raise NameError
  end
  
  it "can be compared directly with a codestring or symbol (bidirectional)" do
    Wires::Event.must_equal    'event'
    CoolEvent.must_equal       'cool'
    MyFavoriteEvent.must_equal 'my_favorite'
    Wires::Event.must_equal    :event
    CoolEvent.must_equal       :cool
    MyFavoriteEvent.must_equal :my_favorite
    'event'.must_equal          Wires::Event
    'cool'.must_equal           CoolEvent
    'my_favorite'.must_equal    MyFavoriteEvent
    :event.must_equal           Wires::Event
    :cool.must_equal            CoolEvent
    :my_favorite.must_equal     MyFavoriteEvent
  end
  
  it "can check inheritance with a codestring or symbol (bidirectional)" do
    CoolEvent.must_be        :<=, :event
    CoolEvent.must_be        :<,  :event
    CoolEvent.must_be        :>,  :my_favorite
    CoolEvent.must_be        :>=, :my_favorite
        
    :event.must_be           :<=, Wires::Event
    :event.must_be           :>=, Wires::Event
    :event.wont_be           :<,  Wires::Event
    :event.wont_be           :>,  Wires::Event
    :cool.must_be            :<=, Wires::Event
    :cool.wont_be            :>=, Wires::Event
    :cool.must_be            :<,  Wires::Event
    :cool.wont_be            :>,  Wires::Event
    :my_favorite.must_be     :<=, Wires::Event
    :my_favorite.wont_be     :>=, Wires::Event
    :my_favorite.must_be     :<,  Wires::Event
    :my_favorite.wont_be     :>,  Wires::Event
    :event.wont_be           :<=, CoolEvent
    :event.must_be           :>=, CoolEvent
    :event.wont_be           :<,  CoolEvent
    :event.must_be           :>,  CoolEvent
    :cool.must_be            :<=, CoolEvent
    :cool.must_be            :>=, CoolEvent
    :cool.wont_be            :<,  CoolEvent
    :cool.wont_be            :>,  CoolEvent
    :my_favorite.must_be     :<=, CoolEvent
    :my_favorite.wont_be     :>=, CoolEvent
    :my_favorite.must_be     :<,  CoolEvent
    :my_favorite.wont_be     :>,  CoolEvent
    :event.wont_be           :<=, MyFavoriteEvent
    :event.must_be           :>=, MyFavoriteEvent
    :event.wont_be           :<,  MyFavoriteEvent
    :event.must_be           :>,  MyFavoriteEvent
    :cool.wont_be            :<=, MyFavoriteEvent
    :cool.must_be            :>=, MyFavoriteEvent
    :cool.wont_be            :<,  MyFavoriteEvent
    :cool.must_be            :>,  MyFavoriteEvent
    :my_favorite.must_be     :<=, MyFavoriteEvent
    :my_favorite.must_be     :>=, MyFavoriteEvent
    :my_favorite.wont_be     :<,  MyFavoriteEvent
    :my_favorite.wont_be     :>,  MyFavoriteEvent
  end
  
  it "can be used to retrieve the Event class associated with a codestring" do
    Wires::Event.from_codestring('event').must_be_same_as Wires::Event
    Wires::Event.from_codestring(:event ).must_be_same_as Wires::Event
    for cls in [CoolEvent, MyFavoriteEvent]
      Wires::Event.from_codestring(cls.codestring).must_be_same_as cls
    end
  end
  
  it "can tell you all about its ancestry" do
    events = [MyFavoriteEvent, CoolEvent, Wires::Event]
    events.each_index do |i|
      events[i].ancestry.must_equal events[i..-1]
    end
  end
  
  it "can tell you the codestrings of it and its ancestors" do
    events = [MyFavoriteEvent, CoolEvent, Wires::Event]
    events.each_index do |i|
      events[i].codestrings.must_equal events[i..-1].map{|cls| cls.codestring}
    end
  end
  
  it "automatically creates attributes, getters, but not setters "\
     "from the initial arguments passed to the constructor" do
    cool = CoolEvent.new(13, 24, 10, 
                         dogname:'Grover', 
                         fishscales:7096) \
                           {'even a passed codeblock gets internalized!'}
    
    cool.args.must_equal [13, 24, 10]
    proc{cool.args = [1,2,3]}.must_raise NoMethodError
    cool.args << 6
    cool.args.must_equal [13, 24, 10, 6]
    
    cool.dogname.must_equal 'Grover'
    cool.fishscales.must_equal 7096
    
    checkhash = Hash.new
    checkhash[:dogname] = 'Grover'
    checkhash[:fishscales] = 7096
    cool.kwargs.must_equal checkhash
    
    assert cool.codeblock.is_a? Proc
    cool.codeblock.call.must_equal 'even a passed codeblock gets internalized!'
  end
  
end
