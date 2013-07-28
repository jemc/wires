require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require 'hegemon'    # State machine management


module WiresBuilder
  @module_procs = []
  
  def self.define(&block)
    @module_procs << block
  end
  
  def self.build(sym, prefix)
    eval("module ::#{sym.to_s}; end", )
    mod = const_get(sym)
    @module_procs.each { |pr| 
      mod.class_exec(prefix, &pr)
    }
    mod
  end
  
end

# require 'wires/builder'
require 'wires/expect_type'
require 'wires/event'
require 'wires/hub'
require 'wires/channel'
require 'wires/time'

# WiresBuilder.define do
#   class self::A
#     def self.foo; puts :yo; end
#   end
  
#   class self::B
#     self.parents[0]::A.foo
#   end
# end


WiresBuilder.build :Wires, nil
p Wires.constants

# include Wires::Convenience # require 'wires/clean' to uninclude Convenience