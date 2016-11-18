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
# @see TnovaManager
class ServiceConfiguration < TnovaManager
    # @method get_modules_services
    # @overload get '/modules/services'
    # Retrieve the microservices list
    get '/services' do
        begin
            return 200, Service.all.to_json
        rescue => e
            logger.error e
            logger.error 'Error Establishing a Database Connection'
            return 500, 'Error Establishing a Database Connection'
        end
    end

    # @method get_modules_services_id
    # @overload get '/modules/services:id'
    # Retrieve a microservice given an id
    get '/services/:id' do |id|
        begin
            service = Service.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'Service not found'
            return 404
        end
        service.to_json
    end

    # @method get_modules_services_name
    # @overload get '/modules/services/:name'
    # Retrieve the token of a microservice given a name
    get '/services/name/:name' do |name|
        begin
            service = Service.find_by(name: name)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'Service not found'
            return 404
        end
        service['token']
    end

    # @method get_modules_services_type
    # @overload get '/modules/services/:type'
    # Retrieve the microservices list by type
    get '/services/type/:type' do |type|
        begin
            services = Service.where(:type => type)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'Service not found'
            return 404
        end
        services.to_json
    end

    # @method post_modules_services
    # @overload post '/modules/services'
    # Register a new microservice
    post '/services' do
        return 415 unless request.content_type == 'application/json'
        serv_reg, errors = parse_json(request.body.read)

        @token = JWT.encode({ service_name: serv_reg['name'] }, serv_reg['secret'], 'HS256')
        serv = {
            name: serv_reg['name'],
            host: serv_reg['host'],
            port: serv_reg['port'],
            path: serv_reg['path'],
            token: @token,
            depends_on: serv_reg['depends_on'],
            type: serv_reg['type']
        }
        logger.debug 'Registring a new service: ' + serv_reg['name']
        begin
            s = Service.find_by(name: serv_reg['name'])
            s.update_attributes!(host: serv_reg['host'], port: serv_reg['port'], token: @token, depends_on: serv_reg['depends_on'], type: serv_reg['type'])
        rescue Mongoid::Errors::DocumentNotFound => e
            Service.create!(serv)
        rescue => e
            logger.error e
            logger.error 'Error saving service.'
            halt 404
        end
        depends_on = []
        serv_reg['depends_on'].each do |serv|
            begin
                logger.debug "Checking if dependant Services of #{serv} is Up and Running...."
                s = Service.where(name: serv).first
                next if s.nil?
                dependant_status = ServiceConfigurationHelper.is_port_open?(s['host'], s['port'])
                if dependant_status == false
                    logger.debug "Service found but is down."
                    s.destroy
                else
                    depends_on << { name: s['name'], host: s['host'], port: s['port'], token: s['token'], depends_on: s['depends_on'], type: s['type'] }
                end
            rescue Mongoid::Errors::DocumentNotFound => e
                logger.error 'Service not found.'
            end
        end

        logger.debug 'Find services that have this module as dependency:'
        dependencies = Service.any_of(depends_on: serv[:name]).entries
        if dependencies.any?
            dependencies.each do |dependency|
                ServiceConfigurationHelper.send_dependencies_to_module(dependency, serv)
            end
        end

        if serv[:type] == 'manager'
            logger.debug "Sending dependencies to VNF Manager..."
            ServiceConfigurationHelper.send_dependencies_to_manager(serv, depends_on)
        end
        halt 201, { depends_on: depends_on }.to_json
    end

    put '/services' do
    end

    # @method delete_modules_services_id
    # @overload delete '/modules/services/:id'
    # Remove a microservice
    delete '/services/:id' do |id|
        begin
           Service.find(id).destroy
       rescue Mongoid::Errors::DocumentNotFound => e
           halt 404
       end
        halt 200
    end

end
