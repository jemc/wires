$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require 'wires'

require 'minitest/autorun'
# require 'turn'
# Turn.config.format  = :outline
# Turn.config.natural = true
# Turn.config.trace   = 5


module Wires
  
  module TestModule
    
    def before_setup
      @received_wires_events = []
      on :event do |e|
        @received_wires_events << e
      end
      
      Hub.run
      super
    end
    
    def after_teardown
      super
      Hub.kill
      
      @received_wires_events.clear
    end
    
    def assert_fired event
      e = Event.new_from event
      assert (@received_wires_events.include? e),
        "Expected #{event.inspect} event to have been fired."
    end
    
  end
  
  class Test < Minitest::Test;  include TestModule;  end
  class Spec < Minitest::Spec;  include TestModule;  end
  
end


# module Kernel # :nodoc:
#   def describe desc, additional_desc = nil, &block # :doc:
#     stack = Minitest::Spec.describe_stack
#     name  = [stack.last, desc, additional_desc].compact.join("::")
#     sclas = stack.last || if Class === self && is_a?(Minitest::Spec::DSL) then
#                             self
#                           else
#                             Minitest::Spec.spec_type desc
#                           end

#     cls = sclas.create name, desc

#     stack.push cls
#     cls.class_eval(&block)
#     stack.pop
#     cls
#   end
#   private :describe
# end







class SomeEvent < Wires::Event; end


class MyTest < Wires::Test
  def test_something
    p @received_wires_events
    puts self.class.superclass
    fire SomeEvent
    p @received_wires_events
    
    p @received_wires_events.object_id
    # assert_fired :some
  end
end

# class MySpec < Wires::Spec
#   it "nil" do
#     puts @received_wires_events
#     puts self.class.superclass
#   end
# end
