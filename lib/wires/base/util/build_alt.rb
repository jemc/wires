
module Wires.current_network::Namespace
  module Util
    
    # Build an alternate version of the Wires module that doesn't 
    # know about or interfere with the original Wires module.
    # Specify the module_path as a string, starting with global locator '::':
    # >> module MyModule; end
    # >> Wires::Util.build_alt "::MyModule::MyWires"
    def self.build_alt(module_path)
      eval "#{module_path} = Wires.replicate"
    end
    
  end
end
