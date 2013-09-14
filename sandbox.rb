$LOAD_PATH.unshift(File.expand_path("./lib", File.dirname(__FILE__)))
require 'wires'
include Wires

# require 'wires/test'
# begin require 'jemc/reporter'; rescue LoadError; end

p Channel['*']   .relevant_channels
p Channel['*']   .relevant_channels
p Channel['abc'] .relevant_channels
p Channel[/abc/] .relevant_channels 
p Channel['abc'] .relevant_channels