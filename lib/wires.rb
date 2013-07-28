require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require 'hegemon'    # State machine management


module WiresBuilder
  @module_procs = []
  
  def self.module(&block)
    @module_procs << block
  end
  
  def self.prefix_method(*syms, format: :underscore)
    
    for sym in syms.map { |sym| sym.to_sym } do
      
      newsym = @current_prefix ? 
                (@current_prefix.to_s+'_'+sym.to_s).send(format) : 
                sym
      @module_procs << Proc.new do
        class_eval("
          alias :#{newsym} :#{sym}
          remove_method :#{sym}
        ") unless sym==newsym
      end
    end
    
  end
  
  def self.build(sym, prefix=nil)
    eval("module ::#{sym.to_s}; end", )
    mod = const_get(sym)
    @current_prefix = prefix
    @module_procs.each { |pr| 
      mod.class_exec(prefix, &pr)
    }
    @current_prefix 
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


WiresBuilder.build :Wires
p Wires.constants
p Wires::Convenience.instance_methods

WiresBuilder.build :SysWires, 'sys'
p SysWires.constants
p SysWires::Convenience.instance_methods

# include Wires::Convenience # require 'wires/clean' to uninclude Convenience