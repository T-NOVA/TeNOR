root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')
require 'sinatra/gk_auth'

run NsdValidator.new

map('/nsds') { run Validator }