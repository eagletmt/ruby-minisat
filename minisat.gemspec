# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minisat/version'

Gem::Specification.new do |gem|
  gem.name          = "minisat"
  gem.version       = MiniSat::VERSION
  gem.authors       = ["eagletmt"]
  gem.email         = ["eagletmt@gmail.com"]
  gem.summary       = 'Ruby binding for MiniSat'
  gem.description   = gem.summary
  gem.homepage      = ""
  gem.licenses      = 'MIT'

  gem.add_development_dependency 'rspec', '>= 3.0.0'
  gem.add_development_dependency 'rake-compiler'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'redcarpet'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.extensions    = ['ext/minisat/extconf.rb']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.extra_rdoc_files = Dir['ext/minisat/*.cc']
  gem.require_paths = ["lib"]
end
