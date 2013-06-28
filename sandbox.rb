require 'wires'


Hub.run

on :event do p $event end

sleep 1

puts 'killtime!'

Hub.before_kill { puts 'prekill'; fire  [:event, dog:5] }
Hub.after_kill  { puts 'postkill'; fire [:event, blog:72] }

Hub.kill