require 'set'
require 'thread'
require 'active_support/core_ext' # Convenience functions from Rails
require 'threadlock' # Easily add re-entrant lock to instance methods
require 'hegemon'    # State machine management

require 'wires/expect_type'
require 'wires/event'
require 'wires/hub'
require 'wires/channel'
require 'wires/time'