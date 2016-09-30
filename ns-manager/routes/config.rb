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
class ServiceConfigurationController < TnovaManager

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
		logger.info("Unregister service " + params["microservice"])
		unregisterService(params["microservice"])
		logger.info("Service " + @json['name'] + " unregistred correctly")
	end

	# @method delete_configs_services
	# @overload delete '/configs/services/:microservice'
	# Delete a registered service
	delete '/services/:microservice' do
		ServiceModel.find_by(name: params["microservice"]).delete
	end

	# @method get_configs_services
	# @overload get '/configs/services'
	# Get all available services
	get '/services' do
	    if params['name']
			  return ServiceModel.find_by(name: params["name"]).to_json
	    else
			  return ServiceModel.all.to_json
	    end
	end

	# @method put_configs_services
	# @overload put '/configs/services'
	# Update service information
	put '/services' do
		updateService(request.body.read)
		return "Correct update."
	end

	# @method put_configs_services
	# @overload put '/configs/services/:name/status'
	# Update service status
	put '/services/:name/status' do
		@service = ServiceModel.find_by(name: params["name"])
		@service.update_attribute(:status, request.body.read)
		return "Correct update."
	end

  # @method get_configs_services_publish_microservice
  # @overload get '/configs/services/:name/status'
  # Get dependencies for specific microservice, asyncrhonous call
	post '/services/publish/:microservice' do
    name =  params[:microservice]

		registerService(request.body.read)

    Thread.new do
			logger.info "PUBLISHING SERVICES FROM NS MANAGER......... because: " + name
      ServiceConfigurationHelper.publishServices()
    end

    return 200
	end

end