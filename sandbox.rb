# $LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
# require 'wires'

# e = Wires::Event.new(dog:66)
# p e.dog

# require 'wires/test'
# begin require 'jemc/reporter'; rescue LoadError; end

require 'ostruct'

class EventO
  def self.new(*args, &block)
    obj = super
    
    kwargs = args[-1].is_a?(Hash) ? args.pop.dup : Hash.new
    kwargs[:kwargs] = kwargs.dup.freeze
    kwargs[:args]   =   args.dup.freeze unless kwargs.has_key?(:args)
    kwargs[:codeblock] = block if block
    
    for key in kwargs.keys
      att = key.to_s
      obj.instance_variable_set("@#{att}", kwargs[key])
      class_eval { attr_reader att }
      # obj.instance_eval "def #{att}; @#{att}; end"
      # obj.instance_eval { self.attr_reader att }
    end
    
    obj
  end
  
  # Calling super in new with *args will complain if this isn't here
  def initialize(*args, &block); end
end

class EventS < OpenStruct; end

module Whatever; end
module WhateverElse; end

class EventX
  def initialize(*args, **kwargs, &block)
    @kwargs = kwargs.dup
    @kwargs[:args] = args unless @kwargs.key? :args
    @kwargs[:codeblock] = block if block
    @kwargs.freeze
  end
  
  def [](key); @kwargs[key]; end
  
  def method_missing(sym, *args, &block)
    args.empty? and @kwargs.has_key?(sym) ?
      @kwargs[sym] :
      (sym==:kwargs ? @kwargs.dup : super)
  end
end

require 'benchmark'

puts Benchmark.measure { 10000.times { EventO.new(dog:4).dog } }
puts Benchmark.measure { 10000.times { EventS.new(dog:4).dog } }
puts Benchmark.measure { 10000.times { EventX.new(dog:4).dog } }

p EventX.ancestors.take_while{|x| x!=BasicObject}