# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["OGIBAYASHI Hironori"]
  gem.email         = ["ogibayashi@gmail.com"]
  gem.description   = %q{0MQ publisher plugin for fluentd}
  gem.summary       = %q{0MQ publisher plugin for fluentd, use zmq v3.2}
  gem.homepage      = "https://github.com/YueHonghui/fluent-plugin-zmq-pub"
  gem.licenses	    = ["Apache License, Version 2.0"]

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zmq-pub"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.2"
  gem.add_development_dependency "fluentd"
  gem.add_runtime_dependency "fluentd"
  gem.add_development_dependency "ffi-rzmq"
  gem.add_runtime_dependency "ffi-rzmq"
end
