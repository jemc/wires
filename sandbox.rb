$LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
require 'wires'


# class A
  def foo
    "foo"
  end
  
  def foo2
    foo
  end
  
  class A
    def foo
      "bar"
    end
  end
  
  A.new.foo
  A.new.foo2