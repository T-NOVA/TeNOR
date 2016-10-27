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
    # /modules/services
    get '/services' do
        begin
            return 200, Service.all.to_json
        rescue => e
            logger.error e
            logger.error 'Error Establishing a Database Connection'
            return 500, 'Error Establishing a Database Connection'
        end
    end

    get '/services/:id' do |id|
        begin
            service = Service.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'DC not found'
            return 404
        end
        return service.to_json
    end

    get '/services/name/:name' do |name|
        begin
            service = Service.find_by(:name => name)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'DC not found'
            return 404
        end
        return service['token']
    end

    post '/services' do
        return 415 unless request.content_type == 'application/json'
        serv_reg, errors = parse_json(request.body.read)

        @token = JWT.encode({ service_name: serv_reg['name'] }, serv_reg['secret'], 'HS256')
        serv = {
            name: serv_reg['name'],
            host: serv_reg['host'],
            port: serv_reg['port'],
            token: @token,
            depends_on: serv_reg['depends_on']
        }
        logger.debug serv
        begin
            s = Service.find_by(name: serv_reg['name'])
            s.update_attributes!(host: serv_reg['host'], port: serv_reg['port'], token: @token, depends_on: serv_reg['depends_on'])
        rescue Mongoid::Errors::DocumentNotFound => e
            Service.create!(serv)
        rescue => e
            logger.error 'Error saving service.'
            halt 404
        end
        depends_on = []
        serv_reg['depends_on'].each do |serv|
            begin
                logger.info "Checking if dependant Services of #{serv} is Up and Running...."
                s = Service.where(name: serv).first
                next if s.nil?
                dependant_status = is_port_open?(s['host'], s['port'])
                if dependant_status == false
                    logger.info "Service found but is down."
                    s.destroy
                else
                    depends_on << { name: s['name'], host: s['host'], port: s['port'], token: s['token'] }
                end
            rescue Mongoid::Errors::DocumentNotFound => e
                logger.error 'User not found.'
                # halt 404
            end
        end

        logger.error 'Find service that has this module as dependency:'
        # Service
        dependencies = Service.any_of(depends_on: serv[:name]).entries
        logger.debug dependencies
        if dependencies.any?
            dependencies.each do |dependency|
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

    delete '/services/:name' do |name|
        begin
           Service.find_by(:name => name).destroy
       rescue Mongoid::Errors::DocumentNotFound => e
           halt 404
       end
        halt 200
    end

    # DEPRECATED..............

    # @method post_configs_registerService
    # @overload post '/configs/registerService'
    # Register a microservice
    post '/registerService' do
        return registerService(request.body.read)
    end

    # @method post_configs_registerExternalService
    # @overload post '/configs/registerExternalService'
    # Register a external service
    post '/registerExternalService' do
        return registerExternalService(request.body.read)
    end

    # @method post_configs_unRegisterService
    # @overload post '/configs/unRegisterService/:service_id'
    # Unregister a service
    post '/unRegisterService/:microservice' do
        logger.info('Unregister service ' + params['microservice'])
        unregisterService(params['microservice'])
        logger.info('Service ' + @json['name'] + ' unregistred correctly')
    end

    # @method delete_configs_services
    # @overload delete '/configs/services/:microservice'
    # Delete a registered service
    delete '/services/:microservice' do
        ServiceModel.find_by(name: params['microservice']).delete
    end

    # @method get_configs_services
    # @overload get '/configs/services'
    # Get all available services
    get '/services' do
        if params['name']
            return ServiceModel.find_by(name: params['name']).to_json
        else
            return ServiceModel.all.to_json
        end
    end

    # @method put_configs_services
    # @overload put '/configs/services'
    # Update service information
    put '/services' do
        updateService(request.body.read)
        return 'Correct update.'
    end

    # @method put_configs_services
    # @overload put '/configs/services/:name/status'
    # Update service status
    put '/services/:name/status' do
        @service = ServiceModel.find_by(name: params['name'])
        @service.update_attribute(:status, request.body.read)
        return 'Correct update.'
    end

    # @method get_configs_services_publish_microservice
    # @overload get '/configs/services/:name/status'
    # Get dependencies for specific microservice, asyncrhonous call
    post '/services/publish/:microservice' do
        name = params[:microservice]

        registerService(request.body.read)

        Thread.new do
            logger.debug 'Publishing `' + name + '` to other services services...'
            ServiceConfigurationHelper.publishServices
        end

        return 200
    end
end
