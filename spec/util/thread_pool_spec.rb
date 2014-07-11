
require 'spec_helper'


describe Wires::Util::ThreadPool do
  
  subject { Wires::Util::ThreadPool.new min_threads, max_threads }
  let(:min_threads) { 3 }
  let(:max_threads) { 5 }
  
  its(:min) { should eq min_threads }
  its(:max) { should eq max_threads }
  
  it "creates the minimum number of threads on creation" do
    original_count = Thread.list.count
    
    subject
    
    Thread.list.count.should eq original_count + min_threads
  end
  
  it "creates no more than the maximum number of threads" do
    release = false
    original_count = Thread.list.count
    
    (max_threads+3).times { subject.process { Thread.pass until release } }
    
    Thread.list.count.should eq original_count + max_threads
    release = true
    subject.wait_until_done
  end
  
end
