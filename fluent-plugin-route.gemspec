# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-route"
  gem.version       = "0.1.2"
  gem.authors       = ["TAGOMORI Satoshi", "FURUHASHI Sadayuki"]
  gem.email         = ["tagomoris@gmail.com", "frsyuki@gmail.com"]
  gem.summary       = %q{Fluentd plugin to route messages in fluentd processes}
  gem.description   = %q{This is copy of out_route.rb originally written by frsyuki}
  gem.homepage      = "https://github.com/tagomoris/fluent-plugin-route"
  gem.license       = "APLv2"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluent-mixin-config-placeholders"
end
