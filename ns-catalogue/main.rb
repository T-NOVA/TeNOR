# Set environment
ENV['RACK_ENV'] ||= 'production'

require 'sinatra'
require 'sinatra/config_file'
require 'yaml'
require 'logstash-logger'

# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/init'

configure do
	# Configure logging
	enable :logging
	Dir.mkdir("#{settings.root}/log") unless File.exists?("#{settings.root}/log")
	log_file = File.new("#{settings.root}/log/#{settings.environment}.log", "a+")
	log_file.sync = true
	use Rack::CommonLogger, log_file
end

before do
	logger.level = Logger::DEBUG
end

class OrchestratorNsCatalogue < Sinatra::Application
	register Sinatra::ConfigFile
	# Load configurations
	config_file 'config/config.yml'
	Mongoid.load!('config/mongoid.yml')
	#use Rack::CommonLogger, LogStashLogger.new(host: settings.logstash_host, port: settings.logstash_port)
end
