require 'wires'

class << self
  target_owner = Wires::Convenience
  target_owner.instance_methods(false)
              .select { |sym| respond_to?(sym) }
              .select { |sym| method(sym).owner==target_owner }
              .each   { |sym| undef_method sym }
end