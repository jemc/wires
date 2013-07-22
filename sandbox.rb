# module A
#   require "wires"
# end

# p Channel('dog')

# p method(:Channel)

# class << self
#   target_owner = A
# p ObjectSpace.each_object
#              .select { |o| o.is_a? Method }
#              .reject { |m| m.owner==target_owner }
#              .map {|m| m.name.to_sym }
#              # .each { |m| undef_method m }
# end