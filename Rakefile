
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'yard'

# RSpec tests
RSpec::Core::RakeTask.new :test

# YARD Documentation
YARD::Rake::YardocTask.new :doc do |c|
  c.after = Proc.new do
    system "cp ./yard/common.css ./doc/css/" # Change stylesheet
  end
end

task :g  => :install
task :gp => :release

task :default => :test
