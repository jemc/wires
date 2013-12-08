require 'rake/testtask'
# require 'rdoc/task'
require 'rspec/core/rake_task'

gemname = 'wires'

task :default => :spec

RSpec::Core::RakeTask.new :spec do |c|
  c.pattern = 'spec/**/*.spec.rb'
end


# # Generate documentation.
# RDoc::Task.new :doc do |rd|
#   rd.template = 'starkfish'
#   rd.rdoc_dir = 'doc'
#   rd.rdoc_files.include 'lib/**/*'
# end

# Generate documentation and view.
task :docv => [:doc] do
  exec "xdg-open ./doc/Wires/Channel.html"
end

# Rebuild gem
task :doc do 
  exec "yardoc; cp ./yard/common.css ./doc/css/"
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

