require 'rake/testtask'

gemname = 'wires'


task :default => [:test]
Rake::TestTask.new do |t|
    t.pattern = "spec/*_spec.rb"
end

# Rebuild gem
task :g do exec "
rm #{gemname}*.gem
gem uninstall #{gemname}
gem build #{gemname}.gemspec
gem install #{gemname}*.gem" end
