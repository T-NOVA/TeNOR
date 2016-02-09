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
class TnovaManager < Sinatra::Application

	before do

		if settings.environment == 'development'
			@client_token = "test-token-client-id"
			return
		end

		pass if request.path_info == '/'
		# Validate every request with Gatekeeper
		@client_token = request.env['HTTP_X_AUTH_TOKEN']
		begin
			response = RestClient.get "#{settings.gatekeeper}/token/validate/#{@client_token}", 'X-Auth-Service-Key' => settings.service_key, :content_type => :json
		rescue Errno::ECONNREFUSED
			halt 500, 'Gatekeeper unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end
	end

	# @method get_root
	# @overload get '/'
	# 	Get all available interfaces
	# Get all interfaces
	get '/' do
		return 200, interfaces_list.to_json
	end

	post '/configs/registerService' do
		return registerService(request.body.read)
	end

	post '/configs/unRegisterService/:microservice' do
		logger.info("Unregister service " + params["microservice"])
		unregisterService(params["microservice"])
		logger.info("Service " + @json['name'] + " unregistred correctly")
	end

	delete '/configs/services/:microservice' do
		ServiceModel.find_by(name: params["microservice"]).delete
	end

	get '/configs/services' do
	    if params['name']
			return ServiceModel.find_by(name: params["name"]).to_json
			#return settings.services[params['name']].to_json
	    else
			return ServiceModel.all.to_json
			#return settings.services.to_json
	    end
	end

 #'/configs/services?name=servicename
	put '/configs/services' do
		updateService(request.body.read)
		return "Correct update."
	end
	
	put '/configs/services/:name/status' do
		@service = ServiceModel.find_by(name: params["name"])
		@service.update_attribute(:status, request.body.read)
		return "Correct update."
	end

end