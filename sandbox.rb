require 'wires'


Hub.run

Hub.before_kill do puts Hub.running? end
Hub.before_kill lambda { puts Hub.running? }
Hub.after_kill do puts Hub.running? end
Hub.after_kill lambda { puts Hub.running? }

sleep 1

Hub.kill