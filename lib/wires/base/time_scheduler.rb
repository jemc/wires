
module Wires.current_network::Namespace
  
  # A singleton class to schedule future firing of events
  class TimeScheduler
    @schedule       = Array.new
    @thread         = Thread.new {nil}
    @schedule_lock  = Monitor.new
    @cond           = @schedule_lock.new_cond
    
    class << self
      
      # Refuse to instantiate; it's a singleton!
      private :new
      
      # Add an event to the schedule
      def add(*args)
        new_item = args.first
        new_item = (TimeSchedulerItem.new *args) \
          unless new_item.is_a? TimeSchedulerItem
        
        new_item.schedulers << self
        schedule_update new_item
        new_item
      end
      
      # Add an event to the schedule using << operator
      def <<(arg); add(*arg); end
      
      # Get a copy of the event schedule from outside the class
      def list; @schedule_lock.synchronize { @schedule.dup } end
      # Clear the event schedule from outside the class
      def clear; @schedule_lock.synchronize { @schedule.clear } end
      # Make the scheduler wake up and re-evaluate
      def refresh; schedule_update end
      
    private
      
      def schedule_update(item_to_add=nil)
        @schedule_lock.synchronize do
          @schedule << item_to_add if item_to_add
          @schedule.select! {|x| x.active?}
          @schedule.sort! {|a,b| a.time <=> b.time}
          @cond.broadcast
        end
      nil end
      
      def main_loop
        pending = []
        loop do
          @schedule_lock.synchronize do
            timeout = (@schedule.first.time_until unless @schedule.empty?)
            @cond.wait timeout
            pending = @schedule.take_while &:ready?
          end
          pending.each &:fire
        end
      nil end
      
    end
    
    @thread = Thread.new { main_loop }
    
  end
  
end
