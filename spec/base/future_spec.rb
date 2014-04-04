
require 'wires'

require 'spec_helper'


describe Wires::Future, iso:true do
  
  subject { Wires::Future.new &codeblock }
  
  let(:codeblock) { Proc.new { return_value } }
  let(:return_value) { Object.new }
  let(:call_args) { [1, 2, 3, a:4, b:5] }
  let(:call_block) { Proc.new { } }
  
  
  its(:codeblock) { should eq codeblock }
  
  it "raises an ArgumentError if instantiated without a block" do
    expect { Wires::Future.new }.to raise_error ArgumentError, /block/
  end
  
  its(:execute) { should eq codeblock.call }
  
  it "can send arguments to the block with execute" do
    codeblock.should_receive(:call) { |*a, &b|
      a.should eq call_args
      b.should eq call_block
      return_value
    }
    subject.execute(*call_args, &call_block).should eq return_value
  end
  
end
