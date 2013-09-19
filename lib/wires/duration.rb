
module Wires
  
  class Duration < ::BasicObject
    
    attr_accessor :value
    
    def ==(other)
      @value==other or (other.is_a?(Duration) and @value==other.value) or super
    end
    
    def initialize(value)
      @value = value
    end
    
    # Reads best without arguments:  10.minutes.ago
    def ago(time = ::Time.now, &block)
      if block
        on :time_scheduler_anon, block.object_id do |e| block.call(e) end
        self.ago(time).fire(:time_scheduler_anon, block.object_id)
      end
      time - @value
    end

    # Reads best with argument:  10.minutes.until(time)
    alias :until :ago

    # Reads best with argument:  10.minutes.since(time)
    def since(time = ::Time.now, &block)
      if block
        on :time_scheduler_anon, block.object_id do |e| block.call(e) end
        self.since(time).fire(:time_scheduler_anon, block.object_id)
      end
      time + @value
    end
    
    def method_missing(meth, *args, &block)
      @value.send(meth, *args, &block)
    end

    # Reads best without arguments:  10.minutes.from_now
    alias :from_now :since
    
  end
  
end
