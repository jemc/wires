
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

# RSpec tests
RSpec::Core::RakeTask.new :test do |c|
  c.pattern = 'spec/**/*.spec.rb'
end

# Yard Documentation
task :doc do 
  exec "yardoc; cp ./yard/common.css ./doc/css/"
end

task :g  => :install
task :gp => :release

task :default => :test
