
require 'wires'

require_relative 'shared'

require 'pry-rescue/rspec'


describe Wires::Convenience do
  subject { Object.new.extend Wires::Convenience }
  
  describe "#fire" do
    it_behaves_like "a non-blocking fire method" do
      let(:on_method)   { Proc.new { |&block|   subject.on   :event, &block } }
      let(:fire_method) { Proc.new { |**kwargs| subject.fire :event, **kwargs } }
    end
  end
  
  describe "#fire!" do
    it_behaves_like "a blocking fire method" do
      let(:on_method)   { Proc.new { |&block|   subject.on    :event, &block } }
      let(:fire_method) { Proc.new { |**kwargs| subject.fire! :event, **kwargs } }
    end
  end
end
