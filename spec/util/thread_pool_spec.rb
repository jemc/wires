
require 'spec_helper'


describe Wires::Util::ThreadPool do
  
  subject { Wires::Util::ThreadPool.new min_threads, max_threads }
  let(:min_threads) { 3 }
  let(:max_threads) { 5 }
  
  it { should be }
  
end
