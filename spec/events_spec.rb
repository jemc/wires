require 'wires'

require 'minitest/spec'
require 'minitest/autorun'

# Set up some events for testing
class CoolEvent       < Event;     end
class MyFavoriteEvent < CoolEvent; end

describe Event do
  
  it "registers itself and its subclasses in EventRegistry.list" do
    EventRegistry.list.must_include Event
    EventRegistry.list.must_include CoolEvent
    EventRegistry.list.must_include MyFavoriteEvent
  end
  
  it "generates a corresponding codestring upon subclass definition" do
    Event.codestring.must_equal           'event'
    CoolEvent.codestring.must_equal       'cool'
    MyFavoriteEvent.codestring.must_equal 'my_favorite'
  end
  
  it "enforces that new subclasses must have a unique codestring" do
    proc{class My_FavoriteEvent < CoolEvent; end}.must_raise NameError
  end
  
  it "can be compared directly with a codestring or symbol (bidirectional)" do
    Event.must_equal           'event'
    CoolEvent.must_equal       'cool'
    MyFavoriteEvent.must_equal 'my_favorite'
    Event.must_equal           :event
    CoolEvent.must_equal       :cool
    MyFavoriteEvent.must_equal :my_favorite
    'event'.must_equal          Event
    'cool'.must_equal           CoolEvent
    'my_favorite'.must_equal    MyFavoriteEvent
    :event.must_equal           Event
    :cool.must_equal            CoolEvent
    :my_favorite.must_equal     MyFavoriteEvent
  end
  
  it "can check inheritance with a codestring or symbol (bidirectional)" do
    CoolEvent.must_be        :<=, :event
    CoolEvent.must_be        :<,  :event
    CoolEvent.must_be        :>,  :my_favorite
    CoolEvent.must_be        :>=, :my_favorite
        
    :event.must_be           :<=, Event
    :event.must_be           :>=, Event
    :event.wont_be           :<,  Event
    :event.wont_be           :>,  Event
    :cool.must_be            :<=, Event
    :cool.wont_be            :>=, Event
    :cool.must_be            :<,  Event
    :cool.wont_be            :>,  Event
    :my_favorite.must_be     :<=, Event
    :my_favorite.wont_be     :>=, Event
    :my_favorite.must_be     :<,  Event
    :my_favorite.wont_be     :>,  Event
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
    Event.from_codestring('event').must_be_same_as Event
    Event.from_codestring(:event ).must_be_same_as Event
    for cls in [CoolEvent, MyFavoriteEvent]
      Event.from_codestring(cls.codestring).must_be_same_as cls
    end
  end
  
  it "can tell you all about its ancestry" do
    events = [MyFavoriteEvent, CoolEvent, Event]
    events.each_index do |i|
      events[i].ancestry.must_equal events[i..-1]
    end
  end
  
  it "can tell you the codestrings of it and its ancestors" do
    events = [MyFavoriteEvent, CoolEvent, Event]
    events.each_index do |i|
      events[i].codestrings.must_equal events[i..-1].map{|cls| cls.codestring}
    end
  end
  
  it "automatically creates attributes, getters, and setters "\
     "from the initial arguments passed to the constructor" do
    cool = CoolEvent.new(13, 24, 10, 
                         dogname:'Grover', 
                         fishscales:7096) \
                           {'even a passed codeblock gets internalized!'}
    
    cool.args.must_equal [13, 24, 10]
    cool.args          = [1,2,3]
    cool.args.must_equal [1,2,3]
    
    cool.dogname.must_equal 'Grover'
    cool.dogname          = 'Trusty'
    cool.dogname.must_equal 'Trusty'
    
    cool.fishscales.must_equal 7096
    cool.fishscales          = 4122 # An unfortunate encounter with Trusty
    cool.fishscales.must_equal 4122
    
    assert cool.codeblock.is_a? Proc
    cool.codeblock.call.must_equal 'even a passed codeblock gets internalized!'
    cool.codeblock = nil
    cool.codeblock.must_be_nil
  end
  
end
