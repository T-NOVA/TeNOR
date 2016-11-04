#
# TeNOR - VNF Manager
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
# @see ServiceConfiguration
class ServiceConfiguration < VNFManager
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
            logger.error 'DC not found'
            return 404
        end
        return service.to_json
    end

    # @method get_modules_services_name
    # @overload get '/modules/services/:name'
    # Retrieve the token of a microservice given a name
    get '/services/name/:name' do |name|
        begin
            service = Service.find_by(name: name)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'DC not found'
            return 404
        end
        service['token']
    end

    # @method post_modules_services
    # @overload get '/modules/services'
    # Register a microservice
    post '/services' do
        return 415 unless request.content_type == 'application/json'
        serv_reg, errors = parse_json(request.body.read)

        if serv_reg['token'].nil?
            @token = JWT.encode({ service_name: serv_reg['name'] }, serv_reg['secret'], 'HS256')
        else
            @token = serv_reg['token']
        end
        serv = {
            name: serv_reg['name'],
            host: serv_reg['host'],
            port: serv_reg['port'],
            path: serv_reg['path'],
            token: @token,
            depends_on: serv_reg['depends_on'],
            type: serv_reg['type']
        }
        logger.debug serv
        begin
            s = Service.find_by(name: serv_reg['name'])
            s.update_attributes!(host: serv_reg['host'], port: serv_reg['port'], token: @token, depends_on: serv_reg['depends_on'], type: serv_reg['type'])
        rescue Mongoid::Errors::DocumentNotFound => e
            Service.create!(serv)
        rescue => e
            logger.error 'Error saving service.'
            halt 404
        end
        depends_on = []
        serv_reg['depends_on'].each do |serv|
            begin
                logger.debug "Checking if dependant Services of #{serv} is Up and Running...."
                s = Service.where(name: serv).first
                next if s.nil?
                dependant_status = is_port_open?(s['host'], s['port'])
                if dependant_status == false
                    logger.debug "Service found but is down."
                    s.destroy
                else
                    logger.debug 'Packing dependent services...'
                    depends_on << { name: s['name'], host: s['host'], port: s['port'], token: s['token'] }
                end
            rescue Mongoid::Errors::DocumentNotFound => e
                logger.error 'Service not found.'
            end
        end

        logger.debug 'Find services that have this module as dependency:'
        dependencies = Service.any_of(depends_on: serv[:name]).entries
        logger.debug dependencies
        if dependencies.any?
            dependencies.each do |dependency|
                puts dependency
                begin
                    RestClient.post dependency['host'] + ':' + dependency['port'] + '/gk_dependencies', serv.to_json, :content_type => :json, 'X-Auth-Token' => dependency['token']
                rescue => e
                    # logger.error e
                    puts e
                    # halt 500, {'Content-Type' => 'text/plain'}, "Error sending dependencies to " +service['name']
                end
            end
        end
        halt 201, { depends_on: depends_on }.to_json
    end

    put '/services' do
    end

    # @method delete_modules_services_name
    # @overload delete '/modules/services/:name'
    # Remove a microservice
    delete '/services/:name' do |name|
        begin
           Service.find_by(name: name).destroy
       rescue Mongoid::Errors::DocumentNotFound => e
           halt 404
       end
        halt 200
    end
end
