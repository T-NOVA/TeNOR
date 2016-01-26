#
# TeNOR - VNF Catalogue
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
# @see OrchestratorVnfCatalogue
class OrchestratorVnfCatalogue < Sinatra::Application

	before do
    	if request.path_info == '/gk_credentials'
      		return
    	end

    	if settings.environment == 'development'
      		return
    	end

    	authorized?
  	end

	# @method get_root
	# @overload get '/'
	#       Get all available interfaces
	# Get all interfaces
    get '/' do
    	halt 200, interfaces_list.to_json
    end
	
	# @method post_vnfs
	# @overload post '/vnfs'
	# 	Post a VNF in JSON format
	# 	@param [JSON] VNF in JSON format
	# Post a VNF
	post '/vnfs' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		vnf = parse_json(request.body.read)

		# Validate VNF
		halt 400, 'ERROR: VNF Name not found' unless vnf.has_key?('name')
		halt 400, 'ERROR: VNFD not found' unless vnf.has_key?('vnfd')

		# Validate VNFD
		begin
			RestClient.post settings.vnfd_validator + '/vnfds', vnf['vnfd'].to_json, 'X-Auth-Token' => @client_token, :content_type => :json
		rescue Errno::ECONNREFUSED
			halt 500, 'VNFD Validator unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		# Save to BD
		begin
			new_vnf = Vnf.create!(vnf)
		rescue Moped::Errors::OperationFailure => e
			halt 400, 'ERROR: Duplicated VNF ID' if e.message.include? 'E11000'
			halt 400, e.message
		end

		halt 200, new_vnf.to_json
	end

	# @method get_vnfs
	# @overload get '/vnfs'
	#	Returns a list of VNFs
	# List all VNFs
	get '/vnfs' do
		params[:offset] ||= 1
		params[:limit] ||= 2

		# Only accept positive numbers
		params[:offset] = 1 if params[:offset].to_i < 1
		params[:limit] = 2 if params[:limit].to_i < 1

		# Get paginated list
		vnfs = Vnf.paginate(:page => params[:offset], :limit => params[:limit])

		# Build HTTP Link Header
		headers['Link'] = build_http_link(params[:offset].to_i, params[:limit])

		halt 200, vnfs.to_json
	end

	# @method get_vnfs_id
	# @overload get '/vnfs/:id'
	#	Show a VNF
	#	@param [String] id VNF ID
	# Show a VNF
	get '/vnfs/:id' do
		begin
			vnf = Vnf.find(params[:id])
		rescue Mongoid::Errors::DocumentNotFound => e
			halt 404
		end

		halt 200, vnf.to_json
	end

	# @method delete_vnfs_id
	# @overload delete '/vnfs/:id'
	#	Delete a VNF by its ID
	#	@param [String] id VNF ID
	# Delete a VNF
	delete '/vnfs/:id' do
		begin
			vnf = Vnf.find(params[:id])
		rescue Mongoid::Errors::DocumentNotFound => e
			halt 404
		end

		vnf.destroy

		halt 200
	end

	# @method put_vnfs_id
	# @overload put '/vnfs/:id'
	#	Update a VNF by its ID
	#	@param [String] id VNF ID
	# Update a VNF
	put '/vnfs/:id' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		new_vnf = parse_json(request.body.read)

		# Validate VNF
		halt 400, 'ERROR: VNF Name not found' unless new_vnf.has_key?('name')
		halt 400, 'ERROR: VNFD not found' unless new_vnf.has_key?('vnfd')

		# Validate VNFD
		begin
			RestClient.post settings.vnfd_validator + '/vnfds', new_vnf['vnfd'].to_json, 'X-Auth-Token' => @client_token, :content_type => :json
		rescue Errno::ECONNREFUSED
			halt 500, 'VNFD Validator unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		# Retrieve stored version
		begin
			vnf = Vnf.find(params[:id])
		rescue Mongoid::Errors::DocumentNotFound => e
			halt 404
		end

		# Update to new version
		vnf.update_attributes(new_vnf)

		halt 200, vnf.to_json
	end
end