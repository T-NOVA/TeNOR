# Set environment
ENV['RACK_ENV'] ||= 'development'

require 'sinatra'
require 'sinatra/config_file'
require 'yaml'
require 'logstash-logger'
require 'eventmachine'

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
end

before do
	logger = LogStashLogger.new(
			type: :multi_logger,
			outputs: [
					{ type: :stdout, formatter: ::Logger::Formatter },
					{ host: settings.logstash_host, port: settings.logstash_port }
			])
	LogStashLogger.configure do |config|
		config.customize_event do |event|
			event["module"] = settings.servicename
		end
	end
	logger.level = Logger::DEBUG
	env['rack.logger'] = logger
end

class OrchestratorNsProvisioner < Sinatra::Application
	register Sinatra::ConfigFile
	# Load configurations
	config_file 'config/config.yml'
end
