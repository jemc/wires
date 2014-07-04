
# Implementation based on Thread::Pool from the 'thread' gem
# (https://github.com/meh/ruby-thread)

module Wires.current_network::Namespace
  module Util
    
    # A pool is a container of a limited amount of threads to which you can add
    # tasks to run.
    #
    # This is usually more performant and less memory intensive than creating a
    # new thread for every task.
    class ThreadPool
      attr_reader :min, :max, :spawned, :waiting
      
      # Create the pool with minimum and maximum threads.
      #
      # The pool will start with the minimum amount of threads created and will
      # spawn new threads until the max is reached in case of need.
      #
      # A default block can be passed, which will be used to {#process} the passed
      # data.
      def initialize (min, max = nil, &block)
        @min   = min
        @max   = max || min
        @block = block
        
        @cond  = ConditionVariable.new
        @mutex = Mutex.new
        
        @done       = ConditionVariable.new
        @done_mutex = Mutex.new
        
        @todo     = []
        @workers  = []
        @timeouts = {}
        
        @spawned       = 0
        @waiting       = 0
        @shutdown      = false
        @trim_requests = 0
        @auto_trim     = false
        @idle_trim     = nil
        
        @mutex.synchronize {
          min.times {
            spawn_thread
          }
        }
      end
      
      # Check if the pool has been shut down.
      def shutdown?; !!@shutdown; end
      
      # Check if auto trimming is enabled.
      def auto_trim?
        @auto_trim
      end
      
      # Enable auto trimming, unneeded threads will be deleted until the minimum
      # is reached.
      def auto_trim!
        @auto_trim = true
      end
      
      # Disable auto trimming.
      def no_auto_trim!
        @auto_trim = false
      end
      
      # Check if idle trimming is enabled.
      def idle_trim?
        !@idle_trim.nil?
      end
      
      # Enable idle trimming. Unneeded threads will be deleted after the given number of seconds of inactivity.
      # The minimum number of threads is respeced.
      def idle_trim!(timeout)
        @idle_trim = timeout
      end
      
      # Turn of idle trimming.
      def no_idle_trim!
        @idle_trim = nil
      end
      
      # Resize the pool with the passed arguments.
      def resize (min, max = nil)
        @min = min
        @max = max || min
        
        trim!
      end
      
      # Get the amount of tasks that still have to be run.
      def backlog
        @mutex.synchronize {
          @todo.length
        }
      end
      
      # Are all tasks consumed ?
      def done?
        @todo.empty? and @waiting == @spawned
      end
      
      # Wait until all tasks are consumed. The caller will be blocked until then.
      def wait_done
        @done_mutex.synchronize {
          return if done?
          @done.wait @done_mutex
        }
      end
      
      # Check if there are idle workers.
      def idle?
        @todo.length < @waiting
      end
      
      # Process Block when there is a idle worker if not block its returns
      def idle (*args, &block)
        while !idle?
          @done_mutex.synchronize {
            break if idle?
            @done.wait @done_mutex
          }
        end
        
        unless block
          return
        end
        
        process *args, &block
        
      end
      
      # Add a task to the pool which will execute the block with the given
      # argument.
      #
      # If no block is passed the default block will be used if present, an
      # ArgumentError will be raised otherwise.
      def process (*args, &block)
        unless block || @block
          raise ArgumentError, 'you must pass a block'
        end
        
        task = Task.new(self, *args, &(block || @block))
        
        @mutex.synchronize {
          raise 'unable to add work while shutting down' if shutdown?
          
          @todo << task
          
          if @waiting == 0 && @spawned < @max
            spawn_thread
          end
          
          @cond.signal
        }
        
        task
      end
      
      alias << process
      
      # Trim the unused threads, if forced threads will be trimmed even if there
      # are tasks waiting.
      def trim (force = false)
        @mutex.synchronize {
          if (force || @waiting > 0) && @spawned - @trim_requests > @min
            @trim_requests += 1
            @cond.signal
          end
        }
        
        self
      end
      
      # Force #{trim}.
      def trim!
        trim true
      end
      
      # Shut down the pool instantly without finishing to execute tasks.
      def shutdown!
        @mutex.synchronize {
          @shutdown = :now
          @cond.broadcast
        }
        
        wake_up_timeout
        
        self
      end
      
      # Shut down the pool, it will block until all tasks have finished running.
      def shutdown
        @mutex.synchronize {
          @shutdown = :nicely
          @cond.broadcast
        }
        
        join
        
        if @timeout
          @shutdown = :now
          
          wake_up_timeout
          
          @timeout.join
        end
        
        self
      end
      
      # Join on all threads in the pool.
      def join
        until @workers.empty?
          if worker = @workers.first
            worker.join
          end
        end
        
        self
      end
      
      # Define a timeout for a task.
      def timeout_for (task, timeout)
        unless @timeout
          spawn_timeout_thread
        end
        
        @mutex.synchronize {
          @timeouts[task] = timeout
          
          wake_up_timeout
        }
      end
      
      # Shutdown the pool after a given amount of time.
      def shutdown_after (timeout)
        Thread.new {
          sleep timeout
          
          shutdown
        }
        
        self
      end
      
      private
      def wake_up_timeout
        if defined? @pipes
          @pipes.last.write_nonblock 'x' rescue nil
        end
      end
      
      def spawn_thread
        @spawned += 1
        
        thread = Thread.new {
          loop do
            task = @mutex.synchronize {
              if @todo.empty?
                while @todo.empty?
                  if @trim_requests > 0
                    @trim_requests -= 1
                    
                    break
                  end
                  
                  break if shutdown?
                  
                  @waiting += 1
                  
                  report_done
                  
                  if @idle_trim and @spawned > @min
                    check_time = Time.now + @idle_trim
                    @cond.wait @mutex, @idle_trim
                    @trim_requests += 1 if Time.now >= check_time && @spawned - @trim_requests > @min
                  else
                    @cond.wait @mutex
                  end
                  
                  @waiting -= 1
                end
                
                break if @todo.empty? && shutdown?
              end
              
              @todo.shift
            } or break
            
            task.execute(thread)
            
            break if @shutdown == :now
            
            trim if auto_trim? && @spawned > @min
          end
          
          @mutex.synchronize {
            @spawned -= 1
            @workers.delete thread
          }
        }
        
        @workers << thread
        
        thread
      end
      
      def spawn_timeout_thread
        @pipes   = IO.pipe
        @timeout = Thread.new {
          loop do
            now     = Time.now
            timeout = @timeouts.map {|task, time|
              next unless task.started_at
              
              now - task.started_at + task.timeout
            }.compact.min unless @timeouts.empty?
            
            readable, = IO.select([@pipes.first], nil, nil, timeout)
            
            break if @shutdown == :now
            
            if readable && !readable.empty?
              readable.first.read_nonblock 1024
            end
            
            now = Time.now
            @timeouts.each {|task, time|
              next if !task.started_at || task.terminated? || task.finished?
              
              if now > task.started_at + task.timeout
                task.timeout!
              end
            }
            
            @timeouts.reject! { |task, _| task.terminated? || task.finished? }
            
            break if @shutdown == :now
          end
        }
      end
      
      def report_done
        @done_mutex.synchronize {
          @done.broadcast if done? or idle?
        }
      end
    end
    
  end
end