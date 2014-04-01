
module Wires.current_network::Namespace
  
  module Actor
    include Wires::Convenience
    
    def self.included(obj)
      obj.extend ClassMethods
    end
    
    def listen_on(*channels, **keyed_channels)
      @_wires_actor_listen_proc ||= Proc.new do |e,c|
        e = e.dup
        e.kwargs[:_wires_actor_original_channel] = c
        @_wires_actor_channel.fire! e
      end
      
      @_wires_actor_listening_channels ||= []
      @_wires_actor_listening_channels.each do |c|
        Channel[c].unregister &@_wires_actor_listen_proc
      end
      
      @_wires_actor_listening_channels = [*channels, **keyed_channels]
      (channels + keyed_channels.values).each do |c|
        Channel[c].register :*, &@_wires_actor_listen_proc
      end
      
      return @_wires_actor_listening_channels
    end
    
    def handler(method_name, event_type: method_name, expand_args: true)
      @_wires_actor_handlers << (
        @_wires_actor_channel.register event_type, weak:true do |e|
          orig_channel = e.kwargs.delete :_wires_actor_original_channel
          if expand_args
            send method_name, *e.args, **e.kwargs, &e.codeblock
          else
            send method_name, e, orig_channel
          end
        end
      )
    end
    
    module ClassMethods
      
      def handler(*args)
        @_wires_actor_handler_events ||= []
        @_wires_actor_handler_events << args
      end
      
      def new(*args)
        super.tap do |obj|
          obj.instance_eval do
            @_wires_actor_handler_events = self.class.instance_variable_get :@_wires_actor_handler_events
            @_wires_actor_handler_events ||= []
            @_wires_actor_handlers = []
            @_wires_actor_channel = Channel.new Object.new
            
            @_wires_actor_handler_events.each { |a| handler(*a) }
          end
        end
      end
      
    end
  end
  
end
