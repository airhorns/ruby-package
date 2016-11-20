# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "ruby-package"
  gem.version       = "0.1.0"
  gem.summary       = "Constant visibility and explicit requirements for ruby"
  gem.description   = ""
  gem.license       = "MIT"
  gem.authors       = ["Harry Brundage"]
  gem.email         = "harry.brundage@gmail.com"
  gem.homepage      = "https://github.com/hornairs/ruby-package#readme"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.10'
end
