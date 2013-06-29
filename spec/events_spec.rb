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
  
  it "generates a corresponding codestring upon request" do
    Event.codestring.must_equal           'event'
    CoolEvent.codestring.must_equal       'cool'
    MyFavoriteEvent.codestring.must_equal 'my_favorite'
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
  
  it "can check inheritance to/from a codestring or symbol" do
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
  
end
