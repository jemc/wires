
module Wires
  
  class Channel
    
    attr_reader :name
    attr_reader :target_list
    attr_accessor :not_firable
    
    def inspect; "#{self.class}(#{name.inspect})"; end
    
    @hub    = Hub
    @router = Router::Default
    @new_lock = Mutex.new
    @@aim_lock = Mutex.new
    
    class << self
      attr_accessor :hub
      attr_accessor :router
      
      def new(*args)
        channel = @new_lock.synchronize do
          router.get_channel(self, *args) { |name| super(name) }        end
      end
      alias_method :[], :new
    end
    
    def initialize(name)
      @name = name
      @target_list = []
    end
    
    # Register a proc to be triggered by an event on this channel
    # Return the proc that was passed in
    def register(*events, &proc)
      if not proc.is_a?(Proc) then raise SyntaxError, \
        "No Proc given to execute on event: #{events}" end
      events = Event.new_from(*events)
      
      @@aim_lock.synchronize do
        @target_list << [events, proc] \
          unless @target_list.include? [events, proc]
      end
      
      proc
    end
    
    # Unregister a proc from the target list of this channel
    # Return true if at least one matching target was unregistered, else false
    def unregister(*events, &proc)
      events = events.empty? ? [] : Event.new_from(*events)
      
      @@aim_lock.synchronize do
        !!(@target_list.reject! do |es,pr|
          (proc and proc==pr) and \
            (events.map{|event| es.map{|e| event=~e}.any?}.all?)
        end)
      end
    end
    
    # Add hook methods
    class << self
      include Util::Hooks
      
      def before_fire(*args, &proc)
        add_hook(:@before_fire, *args, &proc)
      end
      
      def after_fire(*args, &proc)
        add_hook(:@after_fire, *args, &proc)
      end
    end
    
    # Fire an event on this channel
    def fire(input, blocking:false, parallel:!blocking)
      
      raise *@not_firable if @not_firable
      
      return [] << Thread.new { fire(input, blocking:true, parallel:false) } \
        if !blocking and !parallel
      
      backtrace = caller
      
      event = Event.new_from(*input)
      
      case event.count
      when 0
        raise ArgumentError,"Can't create an event from input: #{input.inspect}"
      when 1
        event = event.first
      else
        raise ArgumentError,"Can't fire on multiple events: #{event.inspect}"
      end
      
      self.class.run_hooks(:@before_fire, event, self)
      
      # Select appropriate targets
      procs = []
      @@aim_lock.synchronize do
        self.class.router
        .get_receivers(self).each do |chan|
          chan.target_list.each do |elist, pr|
            elist.each do |e|
              procs << pr if e =~ event
            end
          end
        end
      end
      
      # Fire to selected targets
      threads = procs.uniq.map do |pr|
        self.class.hub.spawn \
          event,     # fired event object event
          self.name, # name of channel fired from
          pr,        # proc to execute
          blocking,  # boolean from blocking kwarg
          parallel,  # boolean from parallel kwarg
          backtrace  # captured backtrace
      end.reject &:nil?
      
      threads.each &:join if blocking and parallel
      
      self.class.run_hooks(:@after_fire, event, self)
      
      threads
    end
    
    # Fire a blocking event on this channel
    def fire!(event)
      kwargs[:blocking] ||= true
      fire(*args, **kwargs)
    end
    
    # Returns true if listening on 'self' would hear a firing on 'other'
    # (not commutative)
    def =~(other)
      (other.is_a? Channel) ?
        (self.class.router.get_receivers(other).include? self) : 
        super
    end
    
    def receivers
      self.class.router.get_receivers self
    end
    
  end
  
end