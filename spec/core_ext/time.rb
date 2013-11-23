
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
