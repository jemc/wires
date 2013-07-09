require 'wires'

require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require_relative '../../hegemon/lib/hegemon'    # State machine management

require_relative '../lib/wires/expect_type'
require_relative '../lib/wires/event'
require_relative '../lib/wires/hub'
require_relative '../lib/wires/channel'
require_relative '../lib/wires/time'

require 'minitest/autorun'
require 'minitest/spec'





include Wires

class MyEvent < Event; end
class MyOtherEvent < Event; end

describe Hub do
  
  it "Can call hooks before and after run and kill" do
    
    hook_val = 'A'
    
    Hub.before_run  { hook_val.must_equal 'A'; hook_val = 'B' }
    Hub.before_run  { hook_val.must_equal 'B'; hook_val = 'C' }
    Hub.after_run   { hook_val.must_equal 'C'; hook_val = 'D' }
    Hub.after_run   { hook_val.must_equal 'D'; hook_val = 'E' }
    
    Hub.before_kill { hook_val.must_equal 'E'; hook_val = 'F' }
    Hub.before_kill { hook_val.must_equal 'F'; hook_val = 'G' }
    Hub.after_kill  { hook_val.must_equal 'G'; hook_val = 'H' }
    Hub.after_kill  { hook_val.must_equal 'H'; hook_val = 'I' }
    
    hook_val.must_equal 'A'
    Hub.run
    hook_val.must_equal 'E'
    Hub.kill
    hook_val.must_equal 'I'
    Hub.run
    Hub.kill :purge_events
    
  end
  
  it "can be run and killed multiple times" do
    
    assert Hub.dead?
    
    Hub.run
    Hub.kill
    Hub.run
    Hub.kill
    
    assert Hub.dead?
    
    Hub.run
    
    assert Hub.alive?
    
    Hub.kill
    Hub.run
    Hub.kill
    
    assert Hub.dead?
    
  end
    
    # on MyEvent do
    #   puts "my event! #{Thread.current}"
    #   fire MyOtherEvent
    # end
    
    # on MyOtherEvent do
    #   puts "my other event! #{Thread.current}"
    # end
    
  # end
end
