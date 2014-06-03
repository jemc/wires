
Gem::Specification.new do |s|
  s.name          = 'wires'
  s.version       = '0.6.1'
  s.date          = '2014-04-02'
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
  
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rb-readline'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'rspec',     '~> 2.99'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'fivemat'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'yard-wires'
end
