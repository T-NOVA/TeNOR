# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "sinatra-gkauth"
  gem.version       = "0.4.0"
  gem.date          = '2016-09-28'
  gem.summary       = %q{}
  gem.description   = %q{This gem allows to authorize the Tenor modules with Gatekeeper.}

  gem.authors       = ["Josep Batallé"]
  gem.email         = ["josep.batalle@i2cat.net"]
  gem.files         = ['lib/sinatra-gkauth.rb']
  gem.require_paths = ["lib"]

  gem.add_dependency 'sinatra', '~>1.4'
  gem.add_dependency 'json', '~>1.8'
  gem.add_dependency 'rest-client', '~>2.0'
  gem.add_dependency 'jwt', '~>1.5.6'
end
