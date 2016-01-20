# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "sinatra-gkauth"
  gem.version       = "0.2.0"
  gem.date          = '2015-01-14'
  gem.summary       = %q{}
  gem.description   = %q{This gem allows to authorize the Tenor modules with Gatekeeper.}

  gem.authors       = ["Josep Batallé"]
  gem.email         = ["josep.batalle@i2cat.net"]
  gem.files         = ['lib/sinatra-gkauth.rb']
  gem.require_paths = ["lib"]

  gem.add_dependency 'sinatra', '~>1.4'
end
