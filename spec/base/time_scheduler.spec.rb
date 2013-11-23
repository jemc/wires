
require 'wires'

require 'spec_helper'


describe Wires::TimeScheduler do
  subject { Wires::TimeScheduler }
  after { Wires::Hub.join_children; subject.clear }
  
  let(:chan_name) { Object.new.tap { |x| x.extend Wires::Convenience } }
  
  it "can accept an existing TimeSchedulerItem with .add" do
    item = Wires::TimeSchedulerItem.new(Time.now+500, :event, chan_name,
                                        interval:3, count:50)
    subject.add item
    expect(subject.list.size).to eq 1
    expect(subject.list).to include item
  end
  
  it "can accept an existing TimeSchedulerItem with .<<" do
    item = Wires::TimeSchedulerItem.new(Time.now+500, :event, chan_name,
                                        interval:3, count:50)
    subject << item
    expect(subject.list.size).to eq 1
    expect(subject.list).to include item
  end
  
  it "can create a new TimeSchedulerItem with .add" do
    subject.add(Time.now+500, :event, chan_name,
                interval:3, count:50)
    expect(subject.list.size).to eq 1
    expect(subject.list[0].interval).to eq 3
    expect(subject.list[0].count   ).to eq 50
  end
  
  it "can create a new TimeSchedulerItem with .<<" do
    subject << [Time.now+500, :event, chan_name,
                interval:3, count:50]
    expect(subject.list.size).to eq 1
    expect(subject.list[0].interval).to eq 3
    expect(subject.list[0].count   ).to eq 50
  end
  
  it "can handle a barrage of events without dropping any" do
    fire_count = 50
    done_count = 0
    go_time = Time.now+0.1
    
    chan_name.on :event do done_count += 1 end
    
    fire_count.times do
      subject.add go_time, :event, chan_name
    end
    
    sleep 0.2
    expect(done_count).to eq fire_count
  end
  
  it "can provide a list of scheduled future events" do
    fire_count = 50
    done_count = 0
    go_time = Time.now+10
    
    chan_name.on :event do done_count += 1 end
    
    fire_count.times do
      subject.add go_time, :event, chan_name
    end
    
    sleep 0.05
    expect(subject.list.size).to eq fire_count
  end
  
  it "can clear the scheduled future events" do
    fire_count = 50
    done_count = 0
    go_time = Time.now+10000
    
    chan_name.on :event do done_count += 1 end
    
    fire_count.times do
      subject.add go_time, :event, chan_name
    end
    
    sleep 0.05
    expect(subject.list).to_not be_empty
    subject.clear
    expect(subject.list).to     be_empty
  end
  
  it "correctly sorts the scheduled future events" do
    count = 0
    
    e = []
    3.times do |i| e << Wires::Event.list_from(:event[index:i]) end
    
    subject << [Time.now+300, e[0], chan_name]
    subject << [Time.now+100, e[1], chan_name]
    subject << [Time.now+200, e[2], chan_name]
    
    e << e.shift
    expect(e).to eq subject.list.map { |x| x.events }
  end
  
end

