
Gem::Specification.new do |s|
  s.name          = 'wires'
  s.version       = '0.5.1'
  s.date          = '2013-11-24'
  s.summary       = "wires"
  s.description   = "A lightweight, extensible asynchronous"\
                    " event routing framework in Ruby."\
                    " Patch your objects together with wires."\
                    " Inspired by the python 'circuits' framework."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/wires/'
  s.licenses      = "Copyright 2013 Joe McIlvain. All rights reserved."
  
  s.add_dependency('threadlock', '~> 1.2')
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fivemat'
  s.add_development_dependency 'timecop'
end
