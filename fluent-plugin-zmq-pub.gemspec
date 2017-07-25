# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["OGIBAYASHI Hironori"]
  gem.email         = ["ogibayashi@gmail.com"]
  gem.description   = %q{0MQ publisher/subscriber plugin for fluentd}
  gem.summary       = %q{0MQ publisher/subscriber plugin for fluentd, use 0MQ v3.2 or greater version}
  gem.homepage      = ""
  gem.licenses	    = ["Apache License, Version 2.0"]

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zmq-pub"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.5"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit", "~> 3.2.0"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "ffi-rzmq"
end
