$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'
include Wires::Convenience

require 'wires/test'
begin require 'jemc/reporter'; rescue LoadError; end

require 'pry-rescue/minitest'


describe Wires::Event do
  
  it "automatically creates attributes, getters, but not setters "\
     "from the initial arguments passed to the constructor" do
    cool = Wires::Event.new(13, 24, 10, 
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
  
  it "clears out old instance methods when given overwriting kwargs" do
    kwargs = Hash[[:clone, :method, :taint, :class, :hash]
                    .map { |k| [k, k.to_s] }]
    
    # The existing methods get wiped out when kwargs overwrite them
    e = Wires::Event.new(**kwargs)
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    
    # The original methods are still in place on other objects
    e = Wires::Event.new
    e.clone.must_be_instance_of Wires::Event
    e.method(:clone).wont_be_nil
    e.class.must_equal Wires::Event
  end
  
  it "uses the specified value for args when :args is a kwarg,"\
     " with a crucial difference being that the specified object"\
     " doesn't get duped or frozen (because it could be anything)." do
    cool = Wires::Event.new(13, 24, 10)
    
    cool.args.must_equal [13, 24, 10]
    proc{cool.args << 6}.must_raise RuntimeError
    cool.args.must_equal [13, 24, 10]
    
    cool = Wires::Event.new(6, 5, 7, args:[13, 24, 10])
    cool.args.must_equal [13, 24, 10]
    cool.args << 6  # wont_raise RuntimeError
    cool.args.must_equal [13, 24, 10, 6]
  end
  
  it "can create an array of events from specially formatted input" do
    e_args = [55, 'blah', dog:14, cow:'moo']
    args = e_args[0...-1]
    kwargs = e_args[-1]
    
    e = Wires::Event.new_from(:symbol=>[*e_args]).first
    e.class.must_equal Wires::Event
    e.args.must_equal args
    e.kwargs.must_equal kwargs
    kwargs.each_pair { |k,v| e.send(k).must_equal v }
    e.type.must_equal :symbol
    
    Proc.new{Wires::Event.new_from('some_string'=>[*e_args])}.must_raise ArgumentError
    
    Proc.new{Wires::Event.new_from(Object=>[*e_args])}.must_raise ArgumentError
    
    e = Wires::Event.new_from(:symbowl).first
    e.class.must_equal Wires::Event
    e.args.must_equal Array.new
    e.kwargs.must_equal Hash.new
    e.type.must_equal :symbowl
    
    ary = [:dog,:wolf,:hound,:mutt]
    e = Wires::Event.new_from ary
    ary.each_with_index do |x,i|
      e[i].class.must_equal Wires::Event
      e[i].type.must_equal x
    end
    
    ary = [dog:[*e_args],wolf:[*e_args],hound:[*e_args],mutt:[*e_args]]
    events = Wires::Event.new_from ary
    ary.last.to_h.each_pair do |key,val|
      e = events.find{|x| x.type==key}
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
        [:dog,                              :dog],
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
        [[:dog,:wolf,:hound,:mutt],         :dog],
        [[:dog,:wolf,:hound,:mutt],         wolf:[55]],
        [[:dog,:wolf,:hound,:mutt],         hound:[arg1:32]],
        [[:dog,:wolf,:hound,:mutt],         Wires::Event.new(type: :mutt)],
      ],
      
      false => [
      # Listening for                         won't receive
        [:dog,                                :cat],
        [{dog:[55]},                          {dog:[66,55]}],
        [{dog:[55,66]},                       {dog:[55]}],
        [{dog:[55,66,77]},                    {dog:[55,66]}],
        [{dog:[arg1:32]},                     {dog:[]}],
        [{dog:[arg1:32]},                     {dog:[32]}],
        [{dog:[arg1:32]},                     {dog:[arg1:33]}],
        [{dog:[55,66,arg1:32]},               {dog:[55,arg1:32]}],
        [{dog:[arg1:32,arg2:88]},             {dog:[arg2:88]}],
        [{dog:[arg1:32,arg2:88]},             {dog:[arg1:32]}],
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
        [[:dog,:wolf,:hound,:mutt],           :cat],
        [[:dog,:wolf,:hound,:mutt],           cat:[55]],
        [[:dog,:wolf,:hound,:mutt],           cat:[arg1:32]],
        [[:dog,:wolf,:hound,:mutt],           Wires::Event.new(type: :cat)],
        [[:dog,:wolf,:hound,:mutt],           Wires::Event.new],
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
  
end
