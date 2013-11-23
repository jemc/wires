
$IN_DEVELOPMENT = true

RSpec.configure do |c|
  if $IN_DEVELOPMENT
    
    # Pry into the context of exceptions and failures
    # begin require 'pry-rescue/rspec'; rescue LoadError; end
    
    # If any tests are marked with iso:true, only run those tests
    c.filter_run_including iso:true
    c.run_all_when_everything_filtered = true
    
    # Abort after first failure
    c.fail_fast = true
  end
  
  # Set output formatter and enable color
  c.formatter = 'Fivemat'
  c.color     = true
  
end


require_relative 'shared/fire'

