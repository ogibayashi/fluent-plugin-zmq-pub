# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Hironori Ogibayashi"]
  gem.email         = ["hironori.ogibayashi@g.softbank.co.jp"]
  gem.description   = %q{0MQ publisher plugin for fluentd}
  gem.summary       = %q{0MQ publisher plugin for fluentd}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zmq-pub"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"
  gem.add_development_dependency "fluentd"
  gem.add_runtime_dependency "fluentd"
end
