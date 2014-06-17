
Gem::Specification.new do |s|
  s.name          = 'wires'
  s.version       = '0.6.2'
  s.date          = '2014-06-08'
  s.summary       = "wires"
  s.description   = "A lightweight, extensible asynchronous"\
                    " event routing framework in Ruby."
  s.authors       = ["Joe McIlvain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/wires/'
  s.licenses      = "Copyright 2013-2014 Joe McIlvain. All rights reserved."
  
  s.add_dependency 'threadlock', '~> 2.0'
  s.add_dependency 'ref',        '~> 1.0'
  
  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'rspec-its',  '~>  1.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
  s.add_development_dependency 'timecop',    '~>  0.7'
  s.add_development_dependency 'yard',       '~>  0.8'
  s.add_development_dependency 'yard-wires', '~>  0.0'
end
