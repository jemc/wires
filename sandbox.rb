
$require_list = []

module Kernel
  def require_and_print(string)
    # $:.each do |p|
    #   if File.exists? File.join(p, string)
    #     puts File.join(p, string)
    #     break
    #   end,
    # end
    $require_list << string
    require_original(string)
  end

  alias_method :require_original, :require
  alias_method :require, :require_and_print

end

# require 'active_support/duration'
# require 'active_support/basic_object'
# require 'active_support/core_ext/array/conversions'
# require 'active_support/core_ext/object/acts_like'


require "active_support/core_ext"
1.seconds.from_now

# puts $require_list.uniq.sort

# p Dir[File.expand_path("./", File.dirname(__FILE__))]#.select{|s| s =~ /activesupport/}
# p $require_list.uniq.select{|s| s =~ /activesupport/}
# p (Dir[File.expand_path('./lib')] - $require_list.uniq).select{|s| s =~ /activesupport/}

# # p Channel('dog')

# # p method(:Channel)

# # class << self
# #   target_owner = A
# # p ObjectSpace.each_object
# #              .select { |o| o.is_a? Method }
# #              .reject { |m| m.owner==target_owner }
# #              .map {|m| m.name.to_sym }
# #              # .each { |m| undef_method m }
# # # end

# # class MyClass
# #   class << self
# #     def initialize_copy(orig)
# #       super
# #       puts 'cloned!'
# #       # Do custom initialization for self
# #     end
# #   end
# # end

# # MyClass.clone
# # # MyClass.dup

# # require 'namespaces'

# # Dogs = Module.new do
# #   p namespaces
# #   def self.foo
# #     p namespaces
# #   end
# # end

# # Dogs.foo

# # module XXX
# #   module Dogs
# #     class self::Terrier
# #       include Namespaces
# #       extend Namespaces
# #       # namespaces
# #       def foo
# #         p namespaces
# #       end
# #       def self.foo
# #         p namespaces
# #       end
# #     end
# #     end
# #   # end

# #   Dogs::Terrier.foo

# #   Rats = Module.new
# #   Rats.const_set(:Terrier, Dogs.const_get(:Terrier).clone)
# #   Rats::Terrier.foo
# # end

# require './spec/wires-devel.rb'
# require 'wrap_in_module'


# module Sys; end
# WrapInModule::wrap_file(Sys, "lib/wires.rb")

# p      Wires.object_id
# p Sys::Wires.object_id

# Wires::Convenience.prefix_methods(:sys)
# p Wires::Convenience.instance_methods
# Wires::Convenience.prefix_methods(:sys) 
# p Wires::Convenience.instance_methods

# # sys_on :event do
# #   nil
# # end

# # module MyMod

# # MyMod = Module.new do

# # MyMod = Module.new
# # MyMod.module_eval do

# #   class self::Bear
# #     p Module.nesting
# #     def self.foo
# #       Module.nesting
# #     end
# #   end
# # end

# # # p MyMod.constants

# # p MyMod::Bear.foo

# p $LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

