
module FireTestHelper
  # Convenience method to test concurrency properties of a firing block
  def fire_test on_method, blocking:false, parallel:!blocking
    count = 0
    running_count = 0
    10.times do
      on_method.call :event, subject do
        if parallel
          expect(count).to eq 0
          sleep 0.1
        else
          expect(count).to eq running_count
          running_count += 1
          sleep 0.01
        end
        count += 1
      end
    end
    
    yield # to block that fires
    
    if not blocking
      expect(count).to eq 0
      sleep 0.15
    end
    expect(count).to eq 10
  end
end


shared_examples "a non-blocking fire method" do
  include FireTestHelper
  
  it "fires non-blocking and in parallel by default" do
    fire_test on_method, blocking:false, parallel:true do
      fire_method.call :event, subject
    end
  end
  
  it "can fire non-blocking and in sequence with parallel:false" do
    fire_test on_method, blocking:false, parallel:false do
      fire_method.call :event, subject,  parallel:false
    end
  end
  
  it "can fire blocking and in sequence with blocking:true" do
    fire_test on_method, blocking:true, parallel:false do
      fire_method.call :event, subject, blocking:true
    end
  end
  
  it "can fire blocking and in parallel with blocking:true, parallel:true" do
    fire_test on_method, blocking:true, parallel:true do
      fire_method.call :event, subject, blocking:true, parallel:true
    end
  end
end


shared_examples "a blocking fire method" do
  include FireTestHelper
  
  it "fires blocking and in sequence by default" do
    fire_test on_method, blocking:true, parallel:false do
      fire_method.call :event, subject
    end
  end
  
  it "can fire blocking and in parallel with parallel:true" do
    fire_test on_method, blocking:true, parallel:true do
      fire_method.call :event, subject, parallel:true
    end
  end
  
  it "can fire non-blocking and in parallel with blocking:false" do
    fire_test on_method, blocking:false, parallel:true do
      fire_method.call :event, subject,  blocking:false
    end
  end
  
  it "can fire non-blocking and in sequence with blocking:false, parallel:false" do
    fire_test on_method, blocking:false, parallel:false do
      fire_method.call :event, subject,  blocking:false, parallel:false
    end
  end
end


shared_examples "a variable-channel fire method" do
  
  let(:event) { Wires::Event.new }
  let(:received) { [] }
  
  it "accepts a channel object as a channel" do
    chan = Wires::Channel[Object.new]
    block = Proc.new do |e,c|
      expect(e).to eq event
      expect(c).to eq chan.name
      received << chan
    end
    expect(on_method.call event, chan, &block).to eq block
    fire_method.call event, chan, blocking:true
    expect(received).to eq [chan]
  end
  
  it "accepts any other object as a channel name" do
    chan = Object.new
    block = Proc.new do |e,c|
      expect(e).to eq event
      expect(c).to eq chan
      received << chan
    end
    expect(on_method.call event, chan, &block).to eq block
    fire_method.call event, chan, blocking:true
    expect(received).to eq [chan]
  end
  
  it "can fire to a handler on a list of channels" do
    chans = 10.times.map { Wires::Channel[Object.new] }
    block = Proc.new do |e,c|
      expect(e).to eq event
      expect(chans.map(&:name)).to include c
      received << c
    end
    expect(on_method.call event, chans, &block).to eq block
    chans.each { |c| fire_method.call event, c, blocking:true }
    expect(received).to match_array chans.map(&:name)
  end
  
end
