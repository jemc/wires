
module Wires.current_network::Namespace
  module Util
    
    # Build an alternate version of the Wires module that doesn't 
    # know about or interfere with the original Wires module.
    # Specify the module_path as a string, starting with global locator '::':
    # >> module MyModule; end
    # >> Wires::Util.build_alt "::MyModule::MyWires"
    def self.build_alt(module_path)
      main_file = File.expand_path("../../base.rb", File.dirname(__FILE__))
      
      token = Object.new
      
      Wires.set_current_network token
      load main_file
      
      the_new_wires = Wires.dup
      the_new_wires.set_current_network token
      
      Wires.set_current_network :main
      
      eval "#{module_path} = the_new_wires"
    end
    
  end
end
