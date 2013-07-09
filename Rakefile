require 'rake/testtask'

gemname = 'wires'

# Run tests
task :default => [:test]
Rake::TestTask.new do |t|
    t.pattern = "spec/*_spec.rb"
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
