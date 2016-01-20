# Set environment
ENV['RACK_ENV'] ||= 'development'

require 'sinatra'
require 'sinatra/config_file'
require 'yaml'
require 'logstash-logger'
#require 'test'

# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

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

class OrchestratorNsdValidator < Sinatra::Application
	register Sinatra::ConfigFile
	# Load configurations
	config_file 'config/config.yml'
	#use Rack::CommonLogger, LogStashLogger.new(port: settings.logstash_port)
end
