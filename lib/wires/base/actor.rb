
module Wires.current_network::Namespace
  
  module Actor
    include Wires::Convenience
    
    def self.included(obj)
      obj.extend ClassMethods
    end
    
    def listen_on(obj)
      @_wires_actor_listen_proc ||= Proc.new do |e,c|
        @_wires_actor_channel.fire! e
      end
      
      @_wires_actor_listening_channels ||= []
      @_wires_actor_listening_channels.each do |c|
        Channel[c].unregister &@_wires_actor_listen_proc
      end
      
      @_wires_actor_listening_channels = [obj]
      @_wires_actor_listening_channels.each do |c|
        Channel[c].register :*, &@_wires_actor_listen_proc
      end
      
      return @_wires_actor_listening_channels
    end
    
    module ClassMethods
      
      def handler(method_name, event_type: method_name)
        @_wires_actor_handler_events ||= []
        @_wires_actor_handler_events << [event_type, method_name]
      end
      
      def new(*args)
        super.tap do |obj|
          obj.instance_eval do
            @_wires_actor_handler_events = self.class.instance_variable_get :@_wires_actor_handler_events
            @_wires_actor_handler_events ||= []
            @_wires_actor_handlers = []
            @_wires_actor_channel = Channel.new Object.new
            
            @_wires_actor_handler_events.each do |event_type, meth|
              @_wires_actor_handlers << (
                @_wires_actor_channel.register event_type, weak:true do |e, c|
                  send meth, *e.args, **e.kwargs, &e.codeblock
                end
              )
            end
          end
        end
      end
      
    end
  end
  
end
