
module Wires
  module Util
    module Hooks
      
      # Register a hook - can be called multiple times if retain is true
      # @param hooks_sym [Symbol] the symbol...
      def add_hook(hooks_sym, retain=false, &proc)
        hooks = instance_variable_get(hooks_sym.to_sym)
        if hooks
          hooks << [proc, retain]
        else
          instance_variable_set(hooks_sym.to_sym, [[proc, retain]])
        end
        proc
      end
      
      # Remove a hook by proc reference
      def remove_hook(hooks_sym, &proc)
        hooks = instance_variable_get(hooks_sym.to_sym)
        return unless hooks
        hooks.reject! {|h| h[0]==proc}
      end
      
    private
      
      # Run all hooks
      def run_hooks(hooks_sym, *exc_args)
        hooks = instance_variable_get(hooks_sym.to_sym)
        return unless hooks
        for hook in hooks
          proc, _ = hook
          proc.call(*exc_args)
        end
      nil end
      
      # Clear hooks not marked for retention (or all hooks if force)
      def clear_hooks(hooks_sym, force=false)
        hooks = instance_variable_get(hooks_sym.to_sym)
        return unless hooks
        (force ? hooks.clear : hooks.select!{|h| h[1]})
      nil end
      
      # Flush/run all hooks, keeping only those marked for retention
      def flush_hooks(hooks_sym, *exc_args)
        hooks = instance_variable_get(hooks_sym.to_sym)
        return unless hooks
        retained = Queue.new
        while not hooks.empty?
          proc, retain = hooks.shift
          retained << [proc, retain] if retain
          proc.call(*exc_args)
        end
        while not retained.empty?
          hooks << retained.shift
        end
      end
    
    end
  end
end