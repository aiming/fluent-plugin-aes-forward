# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-aes-forward"
  spec.version       = "0.0.2"
  spec.authors       = ["Keiji Matsuzaki"]
  spec.email         = ["futoase@gmail.com"]
  spec.description   = %q{fluent plugin aes forward}
  spec.summary       = %q{This plugin is encrypt data at AES while transfer data.}
  spec.homepage      = "https://github.com/aiming/fluent-plugin-aes-forward"
  spec.license       = "Apache License Version 2.0."

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "fluentd"
end
