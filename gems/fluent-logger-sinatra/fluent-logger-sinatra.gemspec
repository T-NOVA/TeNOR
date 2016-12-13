# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent-logger-sinatra/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-logger-sinatra"
  spec.version       = FluentLoggerSinatra::VERSION
  spec.authors       = ["Stephanie Liu", "Josep Batallé"]
  spec.email         = ["sliu14@outlook.com", "josep.batalle@i2cat.net"]

  spec.summary       = %q{Fluent logger for Sinatra applications}
  spec.description   = %q{Fluent logger for Sinatra applications}
  spec.homepage      = "https://github.com/sliuu/fluent-logger-sinatra"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3.0"
  spec.add_runtime_dependency "fluent-logger", "~> 0.5.0"
end
