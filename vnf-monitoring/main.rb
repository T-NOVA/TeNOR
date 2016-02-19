#
# TeNOR - VNF Monitoring
#
# Copyright 2014-2016 i2CAT Foundation, Portugal Telecom Inovação
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Set environment
ENV['RACK_ENV'] ||= 'development'

require 'sinatra'
require 'sinatra/config_file'
require 'yaml'
require 'em-postman'
require "sinatra/reloader"
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
	Dir.mkdir("#{settings.root}/log/") unless File.exists?("#{settings.root}/log/")
	log_file = File.new("#{settings.root}/log/#{settings.environment}.log", "a+")
	log_file.sync = true
	use Rack::CommonLogger, log_file
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

class VNFMonitoring < Sinatra::Application
	register Sinatra::ConfigFile
	# Load configurations
	config_file 'config/config.yml'
	Mongoid.load!('config/mongoid.yml')
end

