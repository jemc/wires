
require 'wires'


describe "wires/core_ext/Symbol#[]" do
  
  describe "without arguments" do
    subject { :some_event[] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:args)      { should eq []           }
    its(:kwargs)    { should eq({})          }
    its(:codeblock) { should_not be }
    
    its([:args])      { should_not be }
    its([:kwargs])    { should_not be }
    its([:codeblock]) { should_not be }
  end
  
  context "with arguments" do
    subject { :some_event[1, 2, 3, a:4, b:5, &:proc] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:args)      { should eq [1, 2, 3] }
    its(:kwargs)    { should eq a:4, b:5  }
    its(:codeblock) { should eq :proc.to_proc }
    
    its([:args])      { should_not be }
    its([:kwargs])    { should_not be }
    its([:codeblock]) { should_not be }
    
    its([:a])    { should eq 4 }
    its([:b])    { should eq 5 }
    
    its(:a)      { should eq 4 }
    its(:b)      { should eq 5 }
  end
  
  context "with :type keyword argument" do
    subject { :some_event[1, 2, 3, a:4, b:5, type: :test, &:proc] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:args)      { should eq [1, 2, 3] }
    its(:kwargs)    { should eq a:4, b:5  }
    its(:codeblock) { should eq :proc.to_proc }
    
    its([:args])      { should_not be }
    its([:kwargs])    { should_not be }
    its([:codeblock]) { should_not be }
    
    its([:a])    { should eq 4 }
    its([:b])    { should eq 5 }
    
    its(:a)      { should eq 4 }
    its(:b)      { should eq 5 }
  end
    
  context "with :args keyword argument" do
    subject { :some_event[1,2,3, args:[5,6,7]] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:args)        { should eq [1, 2, 3] }
    its([:args])      { should eq [5, 6, 7] }
  end
    
  context "with :kwargs keyword argument" do
    subject { :some_event[a:1,b:2, kwargs:{a:4,b:5}] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:kwargs)      { should eq a:1, b:2, kwargs:{a:4,b:5} }
    its([:kwargs])    { should eq({a:4,b:5}) }
  end
  
  context "with :codeblock keyword argument" do
    subject { :some_event[codeblock: :anything, &:proc] }
    
    its(:class)     { should eq Wires::Event }
    its(:type)      { should eq :some_event  }
    
    its(:codeblock)   { should eq :proc.to_proc }
    its([:codeblock]) { should eq :anything }
  end
  
end


# Time objects get extended to call TimeScheduler.add
describe "wires/core_ext/Time" do
  after { Wires::Hub.join_children; Wires::TimeScheduler.clear }
  let(:chan) { Object.new.tap{|x| x.extend Wires::Convenience} }
  
  it "can now fire events at a specific time" do
    var = 'before'
    chan.on :event do var='after' end
    0.1.seconds.from_now.fire :event, chan
    sleep 0.05
    expect(var).to eq 'before'
    sleep 0.15
    expect(var).to eq 'after'
  end
  
  it "will immediately fire events aimed at a time in the past" do
    var = 'before'
    chan.on :event do var='after' end
    0.1.seconds.ago.fire :event, chan
    sleep 0.05
    expect(var).to eq 'after'
    sleep 0.15
    expect(var).to eq 'after'
  end
  
  it "can be told not to fire events aimed at a time in the past" do
    var = 'before'
    chan.on :event do var='after' end
    0.1.seconds.ago.fire :event, chan, ignore_past:true
    sleep 0.05
    expect(var).to eq 'before'
    sleep 0.15
    expect(var).to eq 'before'
  end
  
end


# Duration objects help with syntax sugar and can fire anonymous event blocks
describe "wires/core_ext/Numeric" do
  after { Wires::Hub.join_children; Wires::TimeScheduler.clear }
  
  it "can convert between basic measures of time" do
    {
      [:second,     :seconds]    => '1',
      [:minute,     :minutes]    => '60',
      [:hour,       :hours]      => '3600',
      [:day,        :days]       => '24.hours',
      [:week,       :weeks]      => '7.days',
      [:fortnight,  :fortnights] => '2.weeks',
    }.each_pair do |k,v|
      expect(1.send(k.first)).to eq eval(v)
      expect(1.send(k.last) ).to eq eval(v)
    end
  end
  
  it "calculates consistently with Ruby's time calculations" do
    t = Time.now
    
    times = 
      { :second => :sec, 
        :minute => :min, 
        :hour   => :hour, 
        :day    =>  nil}.to_a
        
    times.each_with_index do |meths, i|
      num_meth, _ = meths
      
      t2 = 1.send(num_meth).from_now(t)
      times[0...i].each do |_, time_meth|
        expect(t.send(time_meth)).to eq t2.send(time_meth)
      end
    end
  end
  
  it "can now fire timed anonymous events, given a code block" do
    var = 'before'
    0.1.seconds.from_now do 
      var = 'after'
    end
    sleep 0.05
    expect(var).to eq 'before'
    sleep 0.15
    expect(var).to eq 'after'
  end
  
  it "can now fire anonymous events at at time related to another time" do
    var = 'before'
    0.1.seconds.until(0.2.seconds.from_now) do 
      var = 'after'
    end
    sleep 0.05
    expect(var).to eq 'before'
    sleep 0.15
    expect(var).to eq 'after'
    
  end
  
  it "can now fire timed anonymous events, which don't match with eachother" do
    fire_count = 20
    done_count = 0
    past_events = []
    
    for i in 0...fire_count
      (i*0.01+0.1).seconds.from_now do |event|
        done_count += 1
        expect(past_events).not_to include event
        past_events << event
      end
    end
    
    sleep (fire_count*0.01+0.2)
    
    expect(done_count).to eq fire_count
  end
  
end