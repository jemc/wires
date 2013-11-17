
module Wires
  
  class Event
    attr_accessor :type
    
    # Return a friendly output upon inspection
    def inspect
      list = [*args, **kwargs].map(&:inspect).join ', '
      the_type = type ? type.inspect : ''
      "#{self.class}#{the_type}(#{list})"
    end
    
    # Internalize all *args and **kwargs and &block to be accessed later
    def initialize(*args, **kwargs, &block)
      @type = kwargs[:type]
      kwargs.delete :type if @type
      
      @ignore = []
      @kwargs = kwargs
      
      (@kwargs[:args] = args; @ignore<<:args) \
        unless @kwargs.has_key? :args
      (@kwargs[:codeblock] = block; @ignore<<:codeblock) \
        unless @kwargs.has_key? :codeblock
      
      @kwargs.keys.each do |m|
        singleton_class.send(:define_method, m) { @kwargs[m] }
      end
    end
    
    # Accessor for @kwargs, including either full contents or 
    # only those that were specified as explicit keyword args
    def kwargs(all=false)
      all ? @kwargs : @kwargs.reject{|k| @ignore.include? k}
    end
    
    # Directly access contents of @kwargs by key
    def [](key); @kwargs[key]; end
    
    # Returns true if listening for 'self' would hear a firing of 'other'
    # (not commutative)
    def =~(other)
      (other.is_a? Event) ? 
        ((self.type.nil? or self.type==other.type) \
          and (not self.kwargs.each_pair.detect{|k,v| other.kwargs[k]!=v}) \
          and (not self.args.each_with_index.detect{|a,i| other.args[i]!=a})) :
        super
    end
    
    # Return an array of Event instance objects generated from
    # specially formatted input (see spec/event_spec.rb).
    def self.new_from(*args)
      args.flatten.each_with_object([]) do |x, list|
        (x.is_a? Hash) ? 
          (x.each_pair { |x,y| list << [x,y] }) :
          (list << [x,[]])
      end.map do |the_type, obj_args|
        case the_type
        when Event;  the_type
        when Symbol; self.new(*obj_args).tap{|e| e.type=the_type}
        end
      end.tap do |x|
        raise ArgumentError, 
        "Invalid event creation input: #{args} \noutput: #{x}" \
          if x.empty? or !x.all?
      end
    end
    
  end
  
end
