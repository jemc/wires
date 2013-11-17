
require 'wires'

require 'pry-rescue/rspec'


describe Wires::Event do
  
  context "without arguments" do
    its(:args)      { should eq []  }
    its(:kwargs)    { should eq({}) }
    its(:codeblock) { should_not be }
    
    its([:args])    { should eq []  }
  end
  
  
  context "with arguments (1, 2, 3, a:4, b:5, &:proc)" do
    subject{ Wires::Event.new 1, 2, 3, a:4, b:5, &:proc }
    
    its(:args)      { should eq [1, 2, 3] }
    its(:kwargs)    { should eq a:4, b:5  }
    its(:codeblock) { should eq :proc.to_proc }
    
    its([:args]) { should eq [1, 2, 3] }
    its([:a])    { should eq 4 }
    its([:b])    { should eq 5 }
    
    its(:a)      { should eq 4 }
    its(:b)      { should eq 5 }
  end
  
  
  describe ".new_from" do
    specify "when given one or several existing instances,"\
            " it returns an array containing them" do
      a,b,c = *3.times.map { Wires::Event.new }
      
      expect(Wires::Event.new_from a)    .to match_array [a]
      expect(Wires::Event.new_from a,b)  .to match_array [a,b]
      expect(Wires::Event.new_from a,b,c).to match_array [a,b,c]
    end
    
    specify "when given one or several symbols,"\
            " it returns an array of empty events with those types" do
      expect(Wires::Event.new_from(:x, :y, :z).map(&:type))
        .to match_array [:x, :y, :z]
    end
    
    specify "when given an array of one or several symbols,"\
            " it returns an array of empty events with those types" do
      expect(Wires::Event.new_from([:x, :y, :z]).map(&:type))
        .to match_array [:x, :y, :z]
    end
    
    specify "when given keyword arguments,"\
            " it interprets the keywords as event types and "\
            " the values as arrays of event creation arguments" do
      args, kwargs = [1, 2, 3], {a:4, b:5}
      events = Wires::Event.new_from x:[*args,**kwargs], 
                                     y:[*args,**kwargs], 
                                     z:[*args,**kwargs]
      expect(events.map(&:type)).to match_array [:x, :y, :z]
      events.each { |event| expect(event.args)  .to eq args }
      events.each { |event| expect(event.kwargs).to eq kwargs }
    end
    
    specify "when given a mixture of symbols and keyword arguments,"\
            " it interprets the symbols and keywords as event types and "\
            " the values as arrays of event creation arguments,"\
            " leaving the symbol-only events empty of creation arguments" do
      args, kwargs = [1, 2, 3], {a:4, b:5}
      events = Wires::Event.new_from :x1, :y1,
                                     x2:[*args,**kwargs],
                                     y2:[*args,**kwargs]
      expect(events.map(&:type)).to match_array [:x1, :y1, :x2, :y2]
      events[2..3].each { |event| expect(event.args)  .to eq args }
      events[2..3].each { |event| expect(event.kwargs).to eq kwargs }
    end
    
    specify "when given an array with both symbols and keyword arguments,"\
            " it interprets the symbols and keywords as event types and "\
            " the values as arrays of event creation arguments,"\
            " leaving the symbol-only events empty of creation arguments" do
      args, kwargs = [1, 2, 3], {a:4, b:5}
      events = Wires::Event.new_from [:x1, :y1,
                                      x2:[*args,**kwargs],
                                      y2:[*args,**kwargs]]
      expect(events.map(&:type)).to match_array [:x1, :y1, :x2, :y2]
      events[2..3].each { |event| expect(event.args)  .to eq args }
      events[2..3].each { |event| expect(event.kwargs).to eq kwargs }
    end
  end
  
  
  describe "#=~" do
    it "performs event pattern matching" do
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
          
          expect(a.count).to be >= 1, 
            "\nBad listen object: #{a} (comes from #{pair[0]})"
          expect(b.count).to be == 1, 
            "\nBad fire object:   #{b} (comes from #{pair[1]})"
          expect(a.map{|x| x=~b.first}.any?).to be == k, 
            "\nBad pair: #{pair} (seen as: #{[a,b]})"
        end
      end
    end
  end
  
end

