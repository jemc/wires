
module Wires.current_network::Namespace
  
  # A module to aid in making objects that interact with {Wires}.
  #
  # Because event handlers created with {Channel#register} or {Convenience#on}
  # are global and permanent (until unregistered), other {Wires} patterns
  # are more conducive to global or singleton structures, but an {OldActor}
  # can easily be more transient and dynamic.
  #
  # An {OldActor} marks one or more of its methods as event handlers with
  # {ClassMethods#handler} or {#handler}, and indicates the channels to 
  # listen on with {#listen_on}. Events fired on those channels will generate
  # invocations of the corresponding marked event handler methods.
  #
  # A basic {OldActor} might look something like this:
  #
  #  class Node
  #    include Wires::OldActor
  #    
  #    def initialize(instream, outstream)
  #      @instream  = instream
  #      @outstream = outstream
  #      @pending_ids = []
  #      listen_on self, :in=>@instream, :out=>@outstream
  #    end
  #    
  #    def request(id, command, payload)
  #      if command_valid? command, payload
  #        fire :pending[id], @outstream
  #        fire :process[id, command, payload], self
  #      else
  #        fire :invalid[id], @outstream
  #      end
  #    end
  #    handler :request, :channel=>:in
  #    
  #    private
  #    
  #    def command_valid?(command, payload)
  #      # ...
  #      # Return true if the command is determined to be valid, else false
  #      # ...
  #    end
  #    
  #    def process(id, command, payload)
  #      # ...
  #      # Do some time consuming operation to produce a result
  #      # ...
  #      @pending_ids -= [id]
  #      fire :done[id, result], @outstream
  #    end
  #    handler :process
  #    
  #    def track_pending(id)
  #      @pending_ids << id
  #    end
  #    handler :track_pending, :event=>:pending, :channel=>:out
  #  end
  #
  module OldActor
    include Wires::Convenience
    
    # When included into a class, extend {ClassMethods} in.
    #
    def self.included(obj)
      obj.extend ClassMethods
    end
    
    # Define the list of channels that the OldActor's handlers listen on.
    # Each subsequent call to {#listen_on} will overwrite the last call,
    # so the entire list of tagged and untagged channels should be specified
    # all in one invocation.
    #
    # @param channels [Array] The untagged channels to listen_on.
    #   An event fired on any one of these channels will be routed to any
    #   {#handler} that did not specify a :channel when {#handler} was
    #   invoked.  Each object in the array is treated as the {Channel#name},
    #   unless it is itself a {Channel} object.
    #
    # @param coded_channels [Hash] The tagged channels to listen_on,
    #   with each key symbol as the channel code, and each value treated as
    #   the {Channel#name} (or {Channel} object).
    #   An event fired on the given channel will be routed to any
    #   {#handler} that specified the same :channel when {#handler} was
    #   invoked.
    #
    # @TODO handle Channel objects instead of names 
    # @TODO handle Channel matching correctly (respecting Router)
    #
    def listen_on(*channels, **coded_channels)
      @_wires_actor_listen_proc ||= Proc.new do |e,c|
        e = e.dup
        e.kwargs[:_wires_actor_original_channel] = c
        @_wires_actor_channel.fire! e
      end
      
      unreg = Proc.new { |c| Channel[c].unregister &@_wires_actor_listen_proc }
      reg = Proc.new { |c| Channel[c].register :*, &@_wires_actor_listen_proc }
      
      @_wires_actor_coded_channels ||= {nil=>[]}
      
      old_channels       = @_wires_actor_coded_channels.delete nil
      old_coded_channels = @_wires_actor_coded_channels
      
      old_channels.each              &unreg
      old_coded_channels.values.each &unreg
      
      channels.each              &reg
      coded_channels.values.each &reg
      
      @_wires_actor_coded_channels      = coded_channels.dup
      @_wires_actor_coded_channels[nil] = channels
      
      nil
    end
    
    # Mark a method by name to receive events of the same type name on the
    # channels specified by the most recent call to {#listen_on}. By default,
    # the method is called with the arguments used in {Event} creation.
    #
    # @param method_name [Symbol] The name of the instance method to mark
    #   as an event handler.
    # @param event [Symbol] The type of events to listen for.
    # @param channel [Symbol] The channel code corresponding to one of
    #   the keywords to be used in a call to {#listen_on}. This channel code
    #   is used rather than a literal {Channel#name} because the name may or
    #   may not be known at the time of {#handler} call; the code will be
    #   resolved to an actual {Channel#name} at time of event reception
    #   based on the last call to {#listen_on}. If no channel is 
    #   specified, the handler will listen for the event on the untagged
    #   channels specified in {#listen_on}.
    #
    # @param expand [Boolean] Specify the form of the arguments to be
    #   passed to the method when called. This argument is +true+ by default,
    #   indicating the default behavior of passing the arguments used in
    #   {Event} creation.  If +false+ is specified, the method will receive
    #   the same arguments a block registered as an event handler with
    #   {Channel#register} or {Convenience#on} would receive - namely,
    #   the {Event} object and the {Channel#name} that it was fired on.
    #
    def handler(method_name,
                event:   method_name,
                channel: nil,
                expand:  true)
      @_wires_actor_handler_procs << (
        @_wires_actor_channel.register event, weak:true do |e|
          orig_channel = e.kwargs.delete :_wires_actor_original_channel
          
          channel_list = @_wires_actor_coded_channels[channel]
          channel_list = [channel_list] unless channel_list.is_a? Array
          
          if channel_list.include? orig_channel
            if expand
              send method_name, *e.args, **e.kwargs, &e.codeblock
            else
              send method_name, e, orig_channel
            end
          end
        end
      )
      
      nil
    end
    
    # A collection of methods to aid in class definitions that include {OldActor}.
    # This module gets extended into the class object by {OldActor.included}.
    #
    module ClassMethods
      
      # This method is used in class definitions to mark a method as an event
      # handler. This creates a delayed call to {OldActor#handler} upon instance
      # object creation inside {#new}.
      #
      # Refer to the argument specification in {OldActor#handler}, because
      # arguments are passed on verbatim.
      #
      def handler(*args)
        @_wires_actor_handlers ||= []
        @_wires_actor_handlers << args
        
        nil
      end
      
      # On object creation, transfer any handlers specified with {#handler}
      # in the class definition into the instance object created.
      #
      def new(*args, &block)
        super(*args, &block).tap do |obj|
          obj.instance_eval do
            @_wires_actor_channel = Channel.new Object.new
            @_wires_actor_handler_procs = []
            @_wires_actor_handlers = 
              self.class.instance_variable_get(:@_wires_actor_handlers) || []
            
            @_wires_actor_handlers.each { |a| handler(*a) }
          end
        end
      end
      
    end
  end
  
end
