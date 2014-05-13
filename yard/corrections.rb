
class WiresNamespaceHandler < YARD::Handlers::Ruby::Base
  handles :module
  
  process do
    statement[0] = YARD::Parser::Ruby::RubyParser.parse("Wires").root \
      if statement[0].source=~/Wires\.current_network::Namespace/
  end
end
