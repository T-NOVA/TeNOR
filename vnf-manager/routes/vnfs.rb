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
# @see OrchestratorVnfManager
class OrchestratorVnfManager < Sinatra::Application

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
	# 	@param [JSON] the VNF
	# Post a VNF
	post '/vnfs' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		vnf = parse_json(request.body.read)

		# Forward request to VNF Catalogue
		begin
			response = RestClient.post settings.vnf_catalogue + request.fullpath, vnf.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
                rescue Errno::ECONNREFUSED
                        halt 500, 'VNF Catalogue unreachable'
		rescue => e
			logger.error e.response
			halt e.response.code, e.response.body
		end

		halt response.code, response.body
	end

        # @method put_vnfs_external_vnf_id
        # @overload put '/vnfs/:external_vnf_id'
        #       Update a VNF
        #       @param [Integer] external_vnf_id VNF external ID
        # Update a VNF
        put '/vnfs/:external_vnf_id' do
                # Return if content-type is invalid
                halt 415 unless request.content_type == 'application/json'

                # Validate JSON format
                vnf = parse_json(request.body.read)

                # Forward request to VNF Catalogue
                begin
                        response = RestClient.put settings.vnf_catalogue + request.fullpath, vnf.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
                rescue Errno::ECONNREFUSED
                        halt 500, 'VNF Catalogue unreachable'
                rescue => e
                        logger.error e.response
                        halt e.response.code, e.response.body
                end

                halt response.code, response.body
        end

	# @method get_vnfs
        # @overload get '/vnfs'
        #       Returns a list of VNFs
        # List all VNFs
        get '/vnfs' do
		# Forward request to VNF Catalogue
                begin
                        response = RestClient.get settings.vnf_catalogue + request.fullpath, 'X-Auth-Token' => @client_token
                rescue Errno::ECONNREFUSED
                        halt 500, 'VNF Catalogue unreachable'
                rescue => e
                        logger.error e.response
                        halt e.response.code, e.response.body
                end

		# Forward response headers
		headers['Link'] = response.headers[:link]

                halt response.code, response.body
        end

	# @method get_vnfs_external_vnf_id
        # @overload get '/vnfs/:external_vnf_id'
        #       Show a VNF
        #       @param [Integer] external_vnf_id VNF external ID
        # Show a VNF
        get '/vnfs/:external_vnf_id' do
		# Forward request to VNF Catalogue
                begin
                        response = RestClient.get settings.vnf_catalogue + request.fullpath, 'X-Auth-Token' => @client_token
                rescue Errno::ECONNREFUSED
                        halt 500, 'VNF Catalogue unreachable'
                rescue => e
                        logger.error e.response
                        halt e.response.code, e.response.body
                end

                halt response.code, response.body
        end

        # @method delete_vnfs_external_vnf_id
        # @overload delete '/vnfs/:external_vnf_id'
        #       Delete a VNF by its external ID
        #       @param [Integer] external_vnf_id VNF external ID
        # Delete a VNF
        delete '/vnfs/:external_vnf_id' do
		# Forward request to VNF Catalogue
                begin
                        response = RestClient.delete settings.vnf_catalogue + request.fullpath, 'X-Auth-Token' => @client_token
                rescue Errno::ECONNREFUSED
                        halt 500, 'VNF Catalogue unreachable'
                rescue => e
                        logger.error e.response
                        halt e.response.code, e.response.body
                end

                halt response.code, response.body
        end

end