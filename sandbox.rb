module A
  def foo
    puts "foob!"
  end
end
module B
  def bar
    puts "foob!"
  end
end

include A
include B

# p method(:foo).owner
# p method(:bar)

class << self
  target_owner = A
p ObjectSpace.each_object
             .select { |o| o.is_a? Method }
             .reject { |m| m.owner==target_owner }
             .map {|m| m.name.to_sym }
             # .each { |m| undef_method m }
end