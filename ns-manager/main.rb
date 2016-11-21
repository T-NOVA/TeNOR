#
# TeNOR - NS Manager
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
require "bcrypt"
require 'jwt'

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

register Sinatra::ConfigFile
# Load configurations
config_file 'config/config.yml'

Mongoid.load!('config/mongoid.yml')

class TnovaManager < Sinatra::Application
    require_relative 'models/init'
    require_relative 'routes/init'
    require_relative 'helpers/init'

    #enable_swagger_doc_endpoint path: '/'

    helpers ApplicationHelper
    helpers ServiceConfigurationHelper
    helpers AuthenticationHelper
    helpers DcHelper
    helpers StatisticsHelper
    helpers VimHelper

    configure do
        # Configure logging
        logger = FluentLoggerSinatra::Logger.new('tenor', settings.servicename, settings.logger_host, settings.logger_port)
        set :logger, logger
    end

    before do
        env['rack.logger'] = settings.logger
        #check token if production
        if settings.environment == 'production' && request.path_info != "/login" && request.path_info != "/services"
            if request.env['HTTP_X_AUTH_TOKEN'].to_s.empty?
                halt 401, { 'Content-Type' => 'text/plain' }, 'Token invalid.'
            end

            if !AuthenticationHelper.check_token(request.env['HTTP_X_AUTH_TOKEN'])
                halt 401, { 'Content-Type' => 'text/plain' }, 'Invalid token'
            end
        end
    end

    #publish services
    ServiceConfigurationHelper.publishModules

    get '/' do
        return 200, JSON.pretty_generate(interfaces_list)
    end
end
