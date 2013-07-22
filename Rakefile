require 'rake/testtask'
require 'rdoc/task'

gemname = 'wires'

# Run tests
task :default => [:test]
Rake::TestTask.new do |t|
    t.pattern = "spec/*_spec.rb"
end

# Generate documentation.
RDoc::Task.new :doc do |rd|
  rd.template = 'starkfish'
  rd.rdoc_dir = 'doc'
  rd.rdoc_files.include 'lib/**/*.rb'
end

# Generate documentation and view.
task :docv => [:doc] do
  exec "xdg-open ./doc/Wires/Channel.html"
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

