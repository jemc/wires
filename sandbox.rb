# # $LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
# require 'wires'

# # Pull in another copy of Wires into Sys::Wires
# require 'wrap_in_module'
# module Sys; end
# wires_rb = $LOAD_PATH.map{|path| File.join(path, "wires.rb")}
#                      .detect{|x| File.exist? x}
# WrapInModule::wrap_file(Sys, wires_rb)

# wires_rb = $LOAD_PATH.map{|path| File.join(path, "wires.rb")}.detect{|x| File.exist? x}

# # Show that the two have differet object ids
# puts      Wires.object_id
# puts Sys::Wires.object_id
# puts 


# # Prefix convenience functions for use
# Sys::Wires::Convenience.prefix_methods(:sys)
# include Sys::Wires::Convenience

# # Show prefixed convenience functions
# p Sys::Wires::Convenience.instance_methods


# ###
# # Show working functionality:

# on :event do |e|
#   puts e
# end
# sys_on :event do |e|
#   puts e
# end


# Wires::Hub.run
# Sys::Wires::Hub.run

# fire :event
# sys_fire :event

# Wires::Hub.kill
# Sys::Wires::Hub.kill

begin
  44-32
rescue
  puts 'whut'
ensure
  puts 'always!'
end