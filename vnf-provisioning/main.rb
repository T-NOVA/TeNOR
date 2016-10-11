#
# TeNOR - VNF Provisioning
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

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

class VnfProvisioning < Sinatra::Application
    Mongoid.load!('config/mongoid.yml')

    require_relative 'routes/init'
    require_relative 'helpers/init'
    require_relative 'models/init'

    helpers ProvisioningHelper

    register Sinatra::ConfigFile
    # Load configurations
    config_file 'config/config.yml'

    configure do
        # Configure logging
        logger = FluentLoggerSinatra::Logger.new('tenor', settings.servicename, settings.logger_host, settings.logger_port)
        set :logger, logger
    end

    before do
        env['rack.logger'] = settings.logger
    end
end
