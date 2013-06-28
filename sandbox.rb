require 'wires'



class StartSchedulerEvent < Event; end

class Thing
  class << self
  
  
  
    private
  
    def main_loop
      puts 'a'
    end
  end
  
  on :start_scheduler, self do; main_loop; end;
  Channel(self).fire(:start_scheduler)
end

sleep 0.2

Hub.run

Hub.before_kill do puts Hub.running? end
Hub.before_kill lambda { puts Hub.running? }
Hub.after_kill do puts Hub.running? end
Hub.after_kill lambda { puts Hub.running? }

sleep 0.2

Hub.kill