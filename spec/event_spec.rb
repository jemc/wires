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
    
    Proc.new{e = CoolEvent.new_from(CoolEvent).first}.must_raise NoMethodError
    
    ary = [:dog,:wolf,:hound,:mutt]
    e = Wires::Event.new_from ary
    ary.each_with_index do |x,i|
      e[i].class.must_equal Wires::Event
      e[i].event_type.must_equal x
    end
    
    ary = [CoolEvent, MyFavoriteEvent]
    e = Wires::Event.new_from ary
    ary.each_with_index do |x,i|
      e[i].class.must_equal x
      e[i].event_type.must_equal x
    end
    
    ary = [dog:[*e_args],wolf:[*e_args],hound:[*e_args],mutt:[*e_args]]
    events = Wires::Event.new_from ary
    ary.last.to_h.each_pair do |key,val|
      e = events.find{|x| x.event_type==key}
      e.class.must_equal Wires::Event
      e.args.must_equal args
      e.kwargs.must_equal kwargs
      kwargs.each_pair { |k,v| e.send(k).must_equal v }
    end
    
    ary = [CoolEvent:[*e_args],MyFavoriteEvent:[*e_args]]
    events = Wires::Event.new_from ary
    ary.last.to_h.each_pair do |key,val|
      e = events.find{|x| x.event_type==key}
      e.class.must_equal Wires::Event
      e.args.must_equal args
      e.kwargs.must_equal kwargs
      kwargs.each_pair { |k,v| e.send(k).must_equal v }
    end
    
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
        [{Wires::Event=>[arg1:32]},         {Wires::Event=>[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {Wires::Event=>[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {Wires::Event=>[55,66,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {Wires::Event=>[55,arg1:32,arg2:33]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {Wires::Event=>[arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {Wires::Event=>[55,arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {Wires::Event=>[55,66,arg1:32,arg2:88]}],
        [{dog:[55]},                        {dog:[55]}],
        [{dog:[55]},                        {dog:[55,66]}],
        [{dog:[55,66]},                     {dog:[55,66]}],
        [{dog:[55,66]},                     {dog:[55,66,77]}],
        [{dog:[arg1:32]},                   {dog:[arg1:32]}],
        [{dog:[arg1:32]},                   {dog:[55,arg1:32]}],
        [{dog:[55,arg1:32]},                {dog:[55,arg1:32]}],
        [{dog:[55,arg1:32]},                {dog:[55,66,arg1:32]}],
        [{dog:[55,arg1:32]},                {dog:[55,arg1:32,arg2:33]}],
        [{dog:[arg1:32,arg2:88]},           {dog:[arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},           {dog:[55,arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},           {dog:[55,66,arg1:32,arg2:88]}],
        [{Wires::Event=>[55]},              {dog:[55]}],
        [{Wires::Event=>[55]},              {dog:[55,66]}],
        [{Wires::Event=>[55,66]},           {dog:[55,66]}],
        [{Wires::Event=>[55,66]},           {dog:[55,66,77]}],
        [{Wires::Event=>[arg1:32]},         {dog:[arg1:32]}],
        [{Wires::Event=>[arg1:32]},         {dog:[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {dog:[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {dog:[55,66,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {dog:[55,arg1:32,arg2:33]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {dog:[arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {dog:[55,arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {dog:[55,66,arg1:32,arg2:88]}],
        [CoolEvent,                         CoolEvent],
        [{CoolEvent=>[55]},                 {CoolEvent=>[55]}],
        [{CoolEvent=>[55]},                 {CoolEvent=>[55,66]}],
        [{CoolEvent=>[55,66]},              {CoolEvent=>[55,66]}],
        [{CoolEvent=>[55,66]},              {CoolEvent=>[55,66,77]}],
        [{CoolEvent=>[arg1:32]},            {CoolEvent=>[arg1:32]}],
        [{CoolEvent=>[arg1:32]},            {CoolEvent=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {CoolEvent=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {CoolEvent=>[55,66,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {CoolEvent=>[55,arg1:32,arg2:33]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {CoolEvent=>[arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {CoolEvent=>[55,arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {CoolEvent=>[55,66,arg1:32,arg2:88]}],
        [Wires::Event,                      CoolEvent],
        [{Wires::Event=>[55]},              {CoolEvent=>[55]}],
        [{Wires::Event=>[55]},              {CoolEvent=>[55,66]}],
        [{Wires::Event=>[55,66]},           {CoolEvent=>[55,66]}],
        [{Wires::Event=>[55,66]},           {CoolEvent=>[55,66,77]}],
        [{Wires::Event=>[arg1:32]},         {CoolEvent=>[arg1:32]}],
        [{Wires::Event=>[arg1:32]},         {CoolEvent=>[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {CoolEvent=>[55,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {CoolEvent=>[55,66,arg1:32]}],
        [{Wires::Event=>[55,arg1:32]},      {CoolEvent=>[55,arg1:32,arg2:33]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {CoolEvent=>[arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {CoolEvent=>[55,arg1:32,arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]}, {CoolEvent=>[55,66,arg1:32,arg2:88]}],
        [CoolEvent,                         MyFavoriteEvent],
        [{CoolEvent=>[55]},                 {MyFavoriteEvent=>[55]}],
        [{CoolEvent=>[55]},                 {MyFavoriteEvent=>[55,66]}],
        [{CoolEvent=>[55,66]},              {MyFavoriteEvent=>[55,66]}],
        [{CoolEvent=>[55,66]},              {MyFavoriteEvent=>[55,66,77]}],
        [{CoolEvent=>[arg1:32]},            {MyFavoriteEvent=>[arg1:32]}],
        [{CoolEvent=>[arg1:32]},            {MyFavoriteEvent=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {MyFavoriteEvent=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {MyFavoriteEvent=>[55,66,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},         {MyFavoriteEvent=>[55,arg1:32,arg2:33]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {MyFavoriteEvent=>[arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {MyFavoriteEvent=>[55,arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},    {MyFavoriteEvent=>[55,66,arg1:32,arg2:88]}],
        [[:dog,:wolf,:hound,:mutt],         :dog],
        [[:dog,:wolf,:hound,:mutt],         wolf:[55]],
        [[:dog,:wolf,:hound,:mutt],         hound:[arg1:32]],
      ],
      
      false => [
      # Listening for                         won't receive
        [:dog,                                :cat],
        [:dog,                                Wires::Event],
        [{Wires::Event=>[55]},                {Wires::Event=>[66,55]}],
        [{Wires::Event=>[55,66]},             {Wires::Event=>[55]}],
        [{Wires::Event=>[55,66,77]},          {Wires::Event=>[55,66]}],
        [{Wires::Event=>[arg1:32]},           {Wires::Event=>[]}],
        [{Wires::Event=>[arg1:32]},           {Wires::Event=>[32]}],
        [{Wires::Event=>[arg1:32]},           {Wires::Event=>[arg1:33]}],
        [{Wires::Event=>[55,66,arg1:32]},     {Wires::Event=>[55,arg1:32]}],
        [{Wires::Event=>[arg1:32,arg2:88]},   {Wires::Event=>[arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]},   {Wires::Event=>[arg1:32]}],
        [{dog:[55]},                          {dog:[66,55]}],
        [{dog:[55,66]},                       {dog:[55]}],
        [{dog:[55,66,77]},                    {dog:[55,66]}],
        [{dog:[arg1:32]},                     {dog:[]}],
        [{dog:[arg1:32]},                     {dog:[32]}],
        [{dog:[arg1:32]},                     {dog:[arg1:33]}],
        [{dog:[55,66,arg1:32]},               {dog:[55,arg1:32]}],
        [{dog:[arg1:32,arg2:88]},             {dog:[arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {dog:[arg1:32]}],
        [{Wires::Event=>[55]},                {dog:[66,55]}],
        [{Wires::Event=>[55,66]},             {dog:[55]}],
        [{Wires::Event=>[55,66,77]},          {dog:[55,66]}],
        [{Wires::Event=>[arg1:32]},           {dog:[]}],
        [{Wires::Event=>[arg1:32]},           {dog:[32]}],
        [{Wires::Event=>[arg1:32]},           {dog:[arg1:33]}],
        [{Wires::Event=>[55,66,arg1:32]},     {dog:[55,arg1:32]}],
        [{Wires::Event=>[arg1:32,arg2:88]},   {dog:[arg2:88]}],
        [{Wires::Event=>[arg1:32,arg2:88]},   {dog:[arg1:32]}],
        [{dog:[55]},                          {cat:[55]}],
        [{dog:[55]},                          {cat:[55,66]}],
        [{dog:[55,66]},                       {cat:[55,66]}],
        [{dog:[55,66]},                       {cat:[55,66,77]}],
        [{dog:[arg1:32]},                     {cat:[arg1:32]}],
        [{dog:[arg1:32]},                     {cat:[55,arg1:32]}],
        [{dog:[55,arg1:32]},                  {cat:[55,arg1:32]}],
        [{dog:[55,arg1:32]},                  {cat:[55,66,arg1:32]}],
        [{dog:[55,arg1:32]},                  {cat:[55,arg1:32,arg2:33]}],
        [{dog:[arg1:32,arg2:88]},             {cat:[arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {cat:[55,arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {cat:[55,66,arg1:32,arg2:88]}],
        [{dog:[55]},                          {Wires::Event=>[55]}],
        [{dog:[55]},                          {Wires::Event=>[55,66]}],
        [{dog:[55,66]},                       {Wires::Event=>[55,66]}],
        [{dog:[55,66]},                       {Wires::Event=>[55,66,77]}],
        [{dog:[arg1:32]},                     {Wires::Event=>[arg1:32]}],
        [{dog:[arg1:32]},                     {Wires::Event=>[55,arg1:32]}],
        [{dog:[55,arg1:32]},                  {Wires::Event=>[55,arg1:32]}],
        [{dog:[55,arg1:32]},                  {Wires::Event=>[55,66,arg1:32]}],
        [{dog:[55,arg1:32]},                  {Wires::Event=>[55,arg1:32,arg2:33]}],
        [{dog:[arg1:32,arg2:88]},             {Wires::Event=>[arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {Wires::Event=>[55,arg1:32,arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {Wires::Event=>[55,66,arg1:32,arg2:88]}],
        [{CoolEvent=>[55]},                   {CoolEvent=>[66,55]}],
        [{CoolEvent=>[55,66]},                {CoolEvent=>[55]}],
        [{CoolEvent=>[55,66,77]},             {CoolEvent=>[55,66]}],
        [{CoolEvent=>[arg1:32]},              {CoolEvent=>[]}],
        [{CoolEvent=>[arg1:32]},              {CoolEvent=>[32]}],
        [{CoolEvent=>[arg1:32]},              {CoolEvent=>[arg1:33]}],
        [{CoolEvent=>[55,66,arg1:32]},        {CoolEvent=>[55,arg1:32]}],
        [{CoolEvent=>[arg1:32,arg2:88]},      {CoolEvent=>[arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},      {CoolEvent=>[arg1:32]}],
        [MyFavoriteEvent,                     CoolEvent],
        [{MyFavoriteEvent=>[55]},             {CoolEvent=>[55]}],
        [{MyFavoriteEvent=>[55]},             {CoolEvent=>[55,66]}],
        [{MyFavoriteEvent=>[55,66]},          {CoolEvent=>[55,66]}],
        [{MyFavoriteEvent=>[55,66]},          {CoolEvent=>[55,66,77]}],
        [{MyFavoriteEvent=>[arg1:32]},        {CoolEvent=>[arg1:32]}],
        [{MyFavoriteEvent=>[arg1:32]},        {CoolEvent=>[55,arg1:32]}],
        [{MyFavoriteEvent=>[55,arg1:32]},     {CoolEvent=>[55,arg1:32]}],
        [{MyFavoriteEvent=>[55,arg1:32]},     {CoolEvent=>[55,66,arg1:32]}],
        [{MyFavoriteEvent=>[55,arg1:32]},     {CoolEvent=>[55,arg1:32,arg2:33]}],
        [{MyFavoriteEvent=>[arg1:32,arg2:88]},{CoolEvent=>[arg1:32,arg2:88]}],
        [{MyFavoriteEvent=>[arg1:32,arg2:88]},{CoolEvent=>[55,arg1:32,arg2:88]}],
        [{MyFavoriteEvent=>[arg1:32,arg2:88]},{CoolEvent=>[55,66,arg1:32,arg2:88]}],
        [CoolEvent,                           Wires::Event],
        [{CoolEvent=>[55]},                   {Wires::Event=>[55]}],
        [{CoolEvent=>[55]},                   {Wires::Event=>[55,66]}],
        [{CoolEvent=>[55,66]},                {Wires::Event=>[55,66]}],
        [{CoolEvent=>[55,66]},                {Wires::Event=>[55,66,77]}],
        [{CoolEvent=>[arg1:32]},              {Wires::Event=>[arg1:32]}],
        [{CoolEvent=>[arg1:32]},              {Wires::Event=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},           {Wires::Event=>[55,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},           {Wires::Event=>[55,66,arg1:32]}],
        [{CoolEvent=>[55,arg1:32]},           {Wires::Event=>[55,arg1:32,arg2:33]}],
        [{CoolEvent=>[arg1:32,arg2:88]},      {Wires::Event=>[arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},      {Wires::Event=>[55,arg1:32,arg2:88]}],
        [{CoolEvent=>[arg1:32,arg2:88]},      {Wires::Event=>[55,66,arg1:32,arg2:88]}],
      ]
    }
    
    for k,set in table
      for pair in set
        a,b = pair.map { |x| Wires::Event.new_from x }
        
        a.count.must_be :>=, 1, "\nBad listen obj: #{a} (comes from #{pair[0]})"
        b.count.must_equal   1, "\nBad fire obj: #{b} (comes from #{pair[1]})"
        a.map do |x|
          x =~ b.first
        end.any?.must_equal k, "\nBad pair: #{pair} (seen as: #{[a,b]})"
      end
    end
    
  end
  
  # it "prints a friendly output when inspected" do
  #   Event.new_from
  # end
  
end
