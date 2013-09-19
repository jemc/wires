require 'set'
require 'thread'
require 'threadlock' # Easily add re-entrant lock to instance methods

require 'wires/util/expect_type'
require 'wires/util/hooks'

require 'wires/event'
require 'wires/hub'
require 'wires/router'
require 'wires/channel'
require 'wires/time'

require 'wires/core_ext'
require 'wires/convenience'
include Wires::Convenience # require 'wires/clean' to uninclude Convenience
