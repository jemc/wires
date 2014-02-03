
YARD::Parser::SourceParser.before_parse_file do |parser|
  str = parser.contents
  str.gsub! 'Wires.current_network::Namespace', 'Wires'
  parser.instance_variable_set :@contents, str
end
