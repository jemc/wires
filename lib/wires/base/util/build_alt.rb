
module Wires
  module Util
    
    # # Build an alternate version of the Wires module that doesn't 
    # # know about or interfere with the original Wires module.
    # # Specify the module_path as a string, starting with global locator '::':
    # # >> module MyModule; end
    # # >> Wires::Util.build_alt "::MyModule::MyWires"
    # def self.build_alt(module_path)
    #   main_file = File.expand_path("../../base.rb", File.dirname(__FILE__))
      
    #   File.read(main_file)
    #     .scan(/require_relative[\s\(]+(["'])(.*)\1/)
    #     .map(&:last)
    #     .map  { |file| File.expand_path("#{file}.rb", File.dirname(main_file)) }
    #     .map  { |file| File.read file }
    #     .each { |code| eval code.gsub("Wires", "#{module_path}") }
      
    #   eval "#{module_path}"
    # end
    
    def self.build_alt(module_path)
      the_module = eval "module #{module_path}; end; #{module_path}"
      
      [:Util, :Hub, :Router, :TimeScheduler, :Convenience].each do |sym|
        the_module.const_set sym, Wires.const_get(sym).dup
        
        new_const = the_module.const_get(sym)
        
        case sym
        when :Util
          new_const.send :remove_const, :Hooks
          new_const.const_set :Hooks, Wires::Util::Hooks.dup
        when :Router
          new_const.send :remove_const, :Default
          new_const.send :remove_const, :Simple
          new_const.const_set :Default, Wires::Router::Default.dup
          new_const.const_set :Simple,  Wires::Router::Simple.dup
        end
      end
      
      the_module.const_set :Event, Wires::Event.dup
      
      the_module.const_set :Channel, Wires::Channel.dup
      the_module.const_get(:Channel).hub    = \
        the_module.const_get(:Hub)
      the_module.const_get(:Channel).router = \
        the_module.const_get(:Router).const_get(:Default)
      
      the_module
    end
    
  end
end
