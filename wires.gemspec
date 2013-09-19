Gem::Specification.new do |s|
  s.name          = 'wires'
  s.version       = '0.3.8'
  s.date          = '2013-09-03'
  s.summary       = "wires"
  s.description   = "An asynchronous (threaded) event routing framework in Ruby."\
                    " Patch your objects together with wires."\
                    " Inspired by the python 'circuits' framework."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/wires/'
  s.licenses      = "Copyright (c) Joe McIlvain. All rights reserved "
  
  s.add_dependency('threadlock', '~> 1.2')
  
  s.add_development_dependency('rake')
  s.add_development_dependency('wires-test')
  s.add_development_dependency('jemc-reporter')
  s.add_development_dependency('starkfish')
end