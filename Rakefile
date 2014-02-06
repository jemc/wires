
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

# RSpec tests
RSpec::Core::RakeTask.new :test

# Yard Documentation
task :doc do 
  code = "./yard/corrections.rb"
  exec "yardoc -e '#{code}'; cp ./yard/common.css ./doc/css/"
end

task :g  => :install
task :gp => :release

task :default => :test
