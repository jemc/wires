require 'rake/testtask'
require 'rdoc/task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

gemname = 'wires'

# task :default => [:test]

# Run tests
Rake::TestTask.new :test do |t|
    t.test_files = Dir['old-spec/*.rb']
end

# Generate documentation.
RDoc::Task.new :doc do |rd|
  rd.template = 'starkfish'
  rd.rdoc_dir = 'doc'
  rd.rdoc_files.include 'lib/**/*'
end

# Generate documentation and view.
task :docv => [:doc] do
  exec "xdg-open ./doc/Wires/Event.html"
end

# Rebuild gem
task :g do exec "
rm #{gemname}*.gem
gem build #{gemname}.gemspec
gem install #{gemname}*.gem" end

# Rebuild and push gem
task :gp do exec "
rm #{gemname}*.gem
gem build #{gemname}.gemspec
gem install #{gemname}*.gem
gem push #{gemname}*.gem" end

