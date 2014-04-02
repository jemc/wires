
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
      
      unreg = Proc.new { |c| Channel[c].unregister &@_wires_actor_listen_proc }
      reg = Proc.new { |c| Channel[c].register :*, &@_wires_actor_listen_proc }
      
      @_wires_actor_keyed_channels ||= {nil=>[]}
      
      old_channels       = @_wires_actor_keyed_channels.delete nil
      old_keyed_channels = @_wires_actor_keyed_channels
      
      old_channels.each              &unreg
      old_keyed_channels.values.each &unreg
      
      channels.each              &reg
      keyed_channels.values.each &reg
      
      @_wires_actor_keyed_channels      = keyed_channels.dup
      @_wires_actor_keyed_channels[nil] = channels
      
      nil
    end
    
    def handler(method_name,
                event_type:  method_name,
                expand_args: true,
                channel:     nil )
      @_wires_actor_handler_procs << (
        @_wires_actor_channel.register event_type, weak:true do |e|
          orig_channel = e.kwargs.delete :_wires_actor_original_channel
          
          channel_list = @_wires_actor_keyed_channels[channel]
          channel_list = [channel_list] unless channel_list.is_a? Array
          
          if channel_list.include? orig_channel
            if expand_args
              send method_name, *e.args, **e.kwargs, &e.codeblock
            else
              send method_name, e, orig_channel
            end
          end
        end
      )
    end
    
    module ClassMethods
      
      def handler(*args)
        @_wires_actor_handlers ||= []
        @_wires_actor_handlers << args
      end
      
      def new(*args)
        super.tap do |obj|
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
