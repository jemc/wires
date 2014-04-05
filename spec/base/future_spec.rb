
require 'wires'

require 'spec_helper'


describe Wires::Future do
  
  subject { Wires::Future.new &codeblock }
  
  let(:codeblock) { Proc.new { return_value } }
  let(:return_value) { Object.new }
  let(:call_args) { [1, 2, 3, a:4, b:5] }
  let(:call_block) { Proc.new { } }
  
  
  its(:codeblock) { should eq codeblock }
  
  it "raises an ArgumentError if instantiated without a block" do
    expect { Wires::Future.new }.to raise_error ArgumentError, /block/
  end
  
  its(:execute) { should eq return_value }
  
  it "can send arguments to the block with execute" do
    codeblock.should_receive(:call) { |*a, &b|
      a.should eq call_args
      b.should eq call_block
      return_value
    }
    subject.execute(*call_args, &call_block).should eq return_value
  end
  
  it "can run in a new thread with start, and join it with join" do
    main_thread = Thread.current
    codeblock.should_receive(:call) { |*a, &b|
      a.should eq call_args
      b.should eq call_block
      Thread.current.should_not eq main_thread
      return_value
    }
    subject.start(*call_args, &call_block).should be_a Thread
    subject.join.should eq return_value
  end
  
  it "can run in a new thread with start, and join it with result" do
    main_thread = Thread.current
    codeblock.should_receive(:call) { |*a, &b|
      a.should eq call_args
      b.should eq call_block
      Thread.current.should_not eq main_thread
      return_value
    }
    subject.start(*call_args, &call_block).should be_a Thread
    subject.result.should eq return_value
  end
  
  it "can be joined after a call to execute" do
    codeblock.should_receive(:call).once.and_call_original
    subject.execute
    subject.join.should eq return_value
    subject.result.should eq return_value
  end
  
  it "can be joined multiple times - subsequent calls do not block" do
    codeblock.should_receive(:call).once.and_call_original
    subject.start
    subject.join.should eq return_value
    subject.join.should eq return_value
    subject.join.should eq return_value
    subject.result.should eq return_value
    subject.result.should eq return_value
    subject.result.should eq return_value
  end
  
  it "can be joined in multiple threads" do
    codeblock.should_receive(:call).once.and_call_original
    subject.start
    [
      Thread.new { subject.join.should eq return_value },
      Thread.new { subject.join.should eq return_value },
      Thread.new { subject.join.should eq return_value },
      Thread.new { subject.result.should eq return_value },
      Thread.new { subject.result.should eq return_value },
      Thread.new { subject.result.should eq return_value },
    ].each &:join
  end
  
  it "can call execute multiple times - it only actually happens once" do
    codeblock.should_receive(:call).once.and_call_original
    subject.execute.should eq return_value
    subject.execute.should eq return_value
    subject.execute.should eq return_value
  end
  
  it "can call start multiple times - it only actually happens once" do
    codeblock.should_receive(:call).once.and_call_original
    subject.start.should be_a Thread
    subject.start.should be_a Thread
    subject.start.should be_a Thread
    subject.join.should eq return_value
  end
  
  it "knows when it is running and when it is complete when using execute" do
    subject.running? .should_not be
    subject.complete?.should_not be
    
    codeblock.should_receive(:call) {
      subject.running? .should be
      subject.complete?.should_not be
      return_value
    }
    subject.execute
    
    subject.running? .should_not be
    subject.complete?.should be
  end
  
  it "knows when it is running and when it is complete when using start" do
    subject.running? .should_not be
    subject.complete?.should_not be
    
    codeblock.should_receive(:call) {
      subject.running? .should be
      subject.complete?.should_not be
      return_value
    }
    subject.start
    subject.join
    
    subject.running? .should_not be
    subject.complete?.should be
  end
  
  it "can be joined before it has even begun" do
    codeblock.should_receive(:call).once.and_call_original
    Thread.new { sleep 0.1; subject.start }
    subject.running?.should_not be
    subject.complete?.should_not be
    subject.join.should eq return_value
    subject.running?.should_not be
    subject.complete?.should be
  end
  
  it "can be duplicated without duplicating running/completion state" do
    subject.execute
    subject.running?.should_not be
    subject.complete?.should be
    
    dupe = subject.dup
    
    dupe.codeblock.should eq subject.codeblock
    dupe.running?.should_not be
    dupe.complete?.should_not be
  end
  
  it "will raise an exception out through result or join" do
    ary = []
    subject = Wires::Future.new { ary += caller; sleep 0.1; raise "whoops" }
    thr = subject.start
    
    check_backtrace = Proc.new do |e|
      ary.each { |line| e.backtrace.should include line }
    end
    
    expect { subject.result }.to raise_error "whoops", &check_backtrace
    expect { subject.result }.to raise_error "whoops", &check_backtrace
    expect { subject.join   }.to raise_error "whoops", &check_backtrace
    expect { subject.join   }.to raise_error "whoops", &check_backtrace
    
    thr.join # No exception raised here
  end
  
end
