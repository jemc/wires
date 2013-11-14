
require 'wires'

require 'pry-rescue/rspec'


RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


describe Wires::Event do
  
  context "without arguments" do
    its(:args)      { should eq []  }
    its(:kwargs)    { should eq({}) }
    its(:codeblock) { should_not be }
    
    its([:args])    { should eq []  }
  end
  
  context "with arguments" do
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
  
end
