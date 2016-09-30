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

	# @method put_configs_config_id
	# @overload put '/configs/:config_id'
	# 	Update a configuration value
	# 	@param [Integer] config_id the configuration ID
	# Update a configuration
	put '/:config_id' do
		halt 501, 'Not implemented yet'

		# Return if service ID is invalid
		halt 400, 'Invalid service ID' unless ['vnf-catalogue', 'vnf-provisioning', 'vnf-monitoring', 'vnf-scaling'].include? params[:config_id]

		begin
			response = RestClient.put settings.ns_manager + '/configs/services', 'X-Auth-Token' => @client_token
		rescue Errno::ECONNREFUSED
			halt 500, 'NS Manager unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		halt response.code, response.body
	end

	# @method get_configs
	# @overload get '/configs'
	# 	List all configurations
	# Get all configs
	get '/' do
		if params['name']
			  return ServiceModel.find_by(name: params["name"]).to_json
	    else
			  return ServiceModel.all.to_json
	    end
	end

	# @method get_configs_config_id
	# @overload get '/configs/:config_id'
	# 	Show a specific configuration
	# 	@param [Integer] config_id the configuration ID
	# Get a specific config
	get '/:config_id' do
		# Forward request to NS Manager
		begin
			response = RestClient.get settings.ns_manager + '/configs/services', {params: {name: params[:config_id]}}, 'X-Auth-Token' => @client_token
		rescue Errno::ECONNREFUSED
			halt 500, 'NS Manager unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		halt response.code, response.body
	end

	# @method delete_configs_config_id
	# @overload delete '/configs/:config_id'
	# 	Delete a specific configuration
	# 	@param [Integer] config_id the configuration ID
	# Delete a configuration
	delete '/:config_id' do
		# Forward request to NS Manager
		begin
			response = RestClient.delete settings.ns_manager + '/configs/services', {params: {name: params[:config_id]}}, 'X-Auth-Token' => @client_token
		rescue Errno::ECONNREFUSED
			halt 500, 'NS Manager unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		halt response.code, response.body
	end

	# @method get_configs_services_publish_microservice
	# @overload get '/configs/services/:name/status'
	# Get dependencies for specific microservice, asyncrhonous call
	post '/services/publish/:microservice' do
		name =  params[:microservice]

		#registerService(request.body.read)

		#Thread.new do
		#	ServiceConfigurationHelper.publishServices()
		#end

		return 200
	end

end