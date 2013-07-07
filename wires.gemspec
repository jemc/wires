Gem::Specification.new do |s|
  s.name          = 'wires'
  s.version       = '0.2.1'
  s.date          = '2013-07-06'
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
  
  s.add_dependency('activesupport')
  s.add_dependency('threadlock')
  s.add_dependency('hegemon')
  
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
end