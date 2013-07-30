# $LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
# require 'wires'

# require 'minitest/autorun'
# require 'minitest/spec'
# # require 'turn'
# # Turn.config.format  = :outline
# # Turn.config.natural = true
# # Turn.config.trace   = 5

# require 'wrap_in_module'
# module Sys; end
# WrapInModule::wrap_file(Sys, "../lib/wires.rb")
# SysWires = Sys::Wires

# describe 'Wires.build_alt' do
  
#   it "builds a distinct module" do
#     Wires.object_id.wont_equal SysWires.object_id
#   end
  
#   Wires.constants.each do |c|
#     eval <<-CODE
#       it "builds a distinct inner #{c}" do
#         Wires::#{c}.object_id.wont_equal SysWires::#{c}.object_id
#       end
#     CODE
#   end
  
#   it "builds Channels that point to a distinct Hub" do
#     SysWires::Channel.hub.object_id.must_equal SysWires::Hub.object_id
#        Wires::Channel.hub.object_id.must_equal    Wires::Hub.object_id
#   end
  
#   # it "builds TimeSchedulerAnonEvents that inherit from a distinct Event" do
#   #   SysWires::Channel.hub.object_id.must_equal SysWires::Hub.object_id
#   #      Wires::Channel.hub.object_id.must_equal    Wires::Hub.object_id
#   # end
  
# end

# class CoolEvent < Wires::Event; end
# class SomeCoolEvent < CoolEvent; end

# p Wires::Event.class_variable_get(:@@registry)
# p SysWires::Event.class_variable_get(:@@registry)