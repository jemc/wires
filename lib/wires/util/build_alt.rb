
module Wires
  module Util
    
    # Build an alternate version of the Wires module that doesn't 
    # know about or interfere with the original Wires module.
    # Specify the module_path as a string, starting with global locator '::':
    # >> module MyModule; end
    # >> Wires::Util.build_alt "::MyModule::MyWires"
    def self.build_alt(module_path)
      main_file = File.expand_path("../clean.rb", File.dirname(__FILE__))
      
      File.read(main_file)
        .scan(/require_relative[\s\(]+(["'])(.*)\1/)
        .map(&:last)
        .map  { |file| File.expand_path("#{file}.rb", File.dirname(main_file)) }
        .map  { |file| File.read file }
        .each { |code| eval code.gsub("Wires", "#{module_path}") }
    end
    
  end
end
