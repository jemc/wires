
require 'wires'


describe Wires::Hub do
  subject { Wires::Hub }
  
  it "is a singleton" do
    expect{ subject.new }.to raise_error NoMethodError
  end
  
  describe "neglecting to spawn new threads" do
    
    # Capture stderr to suppress the expected warning messages
    before { $stderr_save, $stderr = $stderr, ::StringIO.new }
    after  { $stderr = $stderr_save }
    
    # Craft argument set for #spawn
    def make_spargs(block, blocking:false, parallel:!blocking)
      [ nil,      # event
        nil,      # channel
        block,    # proc
        blocking, # blocking
        parallel, # parallel
        nil ]     # fire_bt
    end
    
    
    it "allows the user to set an arbitrary maximum number of children"\
       " and temporarily neglects to spawn all further threads" do
      done_flag = false
      spargs = make_spargs Proc.new { sleep 0.02 until done_flag }
      
      subject.max_children = 3
      expect(subject.max_children).to eq 3
      subject.max_children.times do
        expect(subject.spawn(*spargs)).to be_instance_of Thread
      end
      expect(subject.count_neglected).to eq 0
      expect(subject.spawn(*spargs)).to eq false
      expect(subject.count_neglected).to eq 1
      expect(subject.spawn(*spargs)).to eq false
      expect(subject.count_neglected).to eq 2
      subject.clear_neglected
      expect(subject.count_neglected).to eq 0
      expect(subject.spawn(*spargs)).to eq false
      expect(subject.count_neglected).to eq 1
      
      done_flag = true
      subject.join_children
      
      subject.max_children = nil
    end
    
    
    it "temporarily neglects procs that raise a ThreadError on creation;"\
       " that is, when there are too many threads for the OS to handle" do
      done_flag = false
      spargs = make_spargs Proc.new { sleep 0.02 until done_flag }
      count = 0
      while subject.spawn(*spargs)
        count += 1
        expect(subject.count_neglected).to eq 0
      end
      
      expect(subject.count_neglected).to eq 1
      subject.spawn(*spargs)
      expect(subject.count_neglected).to eq 2
      
      done_flag = true
      subject.join_children
      expect(subject.count_neglected).to eq 0
    end
    
    
    it "temporarily neglects procs that try to spawn as threads"\
       " during Wires::Hub.hold, but allows procs to spawn in place" do
      var = 'before'
      spargs  = make_spargs Proc.new { var = 'after' }
      spargs2 = make_spargs Proc.new { var = 'after' }, blocking:true
      expect(subject.count_neglected).to eq 0
      
      subject.hold do
        expect(subject.count_neglected).to eq 0
        expect(subject.spawn(*spargs)).to eq false
        expect(subject.count_neglected).to eq 1
        sleep 0.1
        expect(var).to eq 'before'
      end
      subject.join_children
      
      expect(var).to eq 'after'
      expect(subject.count_neglected).to eq 0
      
      var = 'before'
      subject.hold do
        expect(subject.count_neglected).to eq 0
        expect(subject.spawn(*spargs2)).to_not eq false
        sleep 0.1
        expect(var).to eq 'after'
      end
      subject.join_children
    end
    
    
    it "logs neglects to $stderr by default," \
       "but allows you to specify a different action if desired" do
      spargs = make_spargs Proc.new { nil }
      
      subject.hold do
        expect(subject.spawn(*spargs)).to eq false
        expect($stderr.size).to be > 0
        $stderr = StringIO.new
        expect($stderr.size).to be == 0
      end
      subject.join_children
      
      expect($stderr.size).to be > 0
      $stderr = StringIO.new
      
      count = 0
      something_happened = false
      subject.on_neglect do |*args|
        expect(args.size).to eq 6
        count += 1
        something_happened = true
      end
      subject.on_neglect_done do |*args|
        expect(args.size).to eq 6
        count -= 1
      end
      
      subject.hold do
        expect(subject.spawn(*spargs)).to eq false
        expect($stderr.size).to be == 0
        expect(something_happened).to eq true
        expect(count).to be > 0
      end
      subject.join_children
      
      expect($stderr.size).to be == 0
      expect(something_happened).to eq true
      expect(count).to be == 0
      
      subject.reset_neglect_procs
    end
    
  end
  
  
  describe "custom exception handling" do
    
    it "lets you set a custom event handler exception handler" do
      chan_name = Object.new.tap { |x| x.extend Wires::Convenience }
      event = Wires::Event.new
      chan_name.on event, chan_name do method_that_isnt_defined end
      
      count = 0
      subject.on_handler_exception do |exc, event, ch_string|
        expect(exc.backtrace).to be
        expect(exc.fire_backtrace).to be
        expect(event).to eq event
        expect(ch_string).to eq chan_name
        count += 1
      end
      
      chan_name.fire! event
      chan_name.fire  event
      
      subject.join_children
      subject.reset_handler_exception_proc
      
      expect(count).to eq 2
    end
    
  end
  
  
  describe "concurrency handling" do
    
    it "can handle events called from other events" do
      chan_name = Object.new.tap { |x| x.extend Wires::Convenience }
      count = 0
      
      chan_name.on :event do |e|
        expect(count).to eq e.i
        count += 1
        chan_name.fire :event[i:e.i+1] unless count >= 10
        sleep 0.02 until count >= 10
      end
      
      chan_name.fire :event[i:0]
      subject.join_children
      expect(count).to eq 10
    end
    
  end
  
end
