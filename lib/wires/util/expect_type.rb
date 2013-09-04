
def expect_type(x, type)
  unless x.is_a? type
    raise "Expected #{x.inspect} to be an instance of #{type}."
  end
end
