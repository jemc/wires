
$LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
require 'wires'
# include Wires::Convenience

# tr = TracePoint.new(:call, :return) do |tp| 
#   p tp
# end
# tr.enable

require 'wrap_in_module'
module Sys; end
WrapInModule::wrap_file(Sys, "lib/wires.rb")

# class Thread
#   class << self
#     alias_method :real_new, :new
    
#     def new(*args, &block)
#       puts 'yoyoy'
#       real_new(*args, &block)
#     end
    
#   end
# end

puts 'yo'
p      Wires.object_id
# p Sys::Wires.object_id
puts 'yo'

# Sys::Wires::Convenience.prefix_methods(:sys)
# p Sys::Wires::Convenience.instance_methods
# include Sys::Wires::Convenience

# on :event do |e|
#   puts e
# end


# sleep 1

Wires::Hub.run
# Sys::Wires::Hub.run

# fire :event
# sys_fire :event

# Wires::Hub.kill
# Sys::Wires::Hub.kill





# Wires::Convenience.prefix_methods(:sys) 
# p Wires::Convenience.instance_methods
