require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require 'hegemon'    # State machine management

require_relative '../lib/wires/expect_type'
require_relative '../lib/wires/event'
require_relative '../lib/wires/hub'
require_relative '../lib/wires/channel'
require_relative '../lib/wires/time'

include Wires::Convenience # require 'wires/clean' to uninclude Convenience