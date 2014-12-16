
module Wires.current_network::Namespace
  
  # A Mailbox is the message receptacle and launcher for Events that get
  # sent to an Actor via the public Mailbox::Slot.
  # This Mailbox should be held private to the Actor and its thread.
  class Mailbox
    
    # A Mailbox::Slot is the public-facing part of the Mailbox.
    # It can freely be shared and used from any thread,
    # unlike the Mailbox or the owning Actor itself.
    class Slot
      def initialize queue
        @queue = queue
      end
      
      # Send the given Event to the malbox owner
      def pass event
        @queue << event.to_wires_event
      end
      
      # Send nil to the mailbox owner, ending message processing
      def bomb!
        @queue << nil
      end
    end
    
    # Create a Mailbox associated with the given Actor.
    def initialize actor
      @actor = actor
      @queue = Queue.new
      @handlers = []
      @slot = Slot.new @queue
    end
    
    attr_reader :actor
    attr_reader :slot
    
    # Register a callable handler for Events matching the given Event(s).
    # Any matching Event dropped in the #slot will cause the handler to
    # called with the Event as the argument.  All handlers are run
    # from the #process_events method in that thread.
    def register *events, &callable
      events = Event.list_from *events
      @handlers << [events, callable]
    end
    
    # Unregister a callable handler for all Events it was registered with.
    def unregister &callable
      !!@handlers.reject! do |stored|
        stored.last.object == callable
      end
      @handlers << [events, callable]
    end
    
    # Wait for events to come in, running the event handlers for each Event
    # dropped in the #slot until someone a nil event is received.
    # Calling this will block the current thread until the nil event.
    def process_events
      while event = @queue.pop
        relevant_handlers = []
        @handlers.each do |elist, handler|
          relevant_handlers << handler if elist.detect { |e| e =~ event }
        end
        
        # This happens in a separate step because the callback code
        # could potentially mutate the @handlers list during iteration.
        relevant_handlers.each do |cb|
          handler.call event
        end
      end
    end
  end
  
end
