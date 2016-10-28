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
# @see Catalogue
class Catalogue < VNFManager

  # @method post_vnfs
  # @overload post '/vnfs'
  # Post a VNF in JSON format
  # @param [JSON] the VNF
  # Post a VNF
  post '/' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    # Validate JSON format
    vnf = parse_json(request.body.read)

    # Forward request to VNF Catalogue
    begin
      response = RestClient.post catalogue.host + '/vnfs', vnf.to_json, 'X-Auth-Token' => catalogue.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue RestClient::ExceptionWithResponse => e
      logger.error e
      halt e.response.code, e.response.body
    rescue => e
      logger.error "ERROR"
      logger.error e
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
  put '/:external_vnf_id' do |external_vnf_id|
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    # Validate JSON format
    vnf = parse_json(request.body.read)

    # Forward request to VNF Catalogue
    begin
      response = RestClient.put catalogue.host + '/vnfs/' + external_vnf_id, vnf.to_json, 'X-Auth-Token' => catalogue.token, :content_type => :json
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
  # Returns a list of VNFs
  # List all VNFs
  get '/' do

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    # Forward request to VNF Catalogue
    begin
      response = RestClient.get catalogue.host + '/vnfs', 'X-Auth-Token' => catalogue.token
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e
      if e.response.nil?
        logger.error e
        halt 400, "Error getting list of VNFs."
      end
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
  get '/:external_vnf_id' do |external_vnf_id|

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    # Forward request to VNF Catalogue
    begin
      response = RestClient.get catalogue.host + '/vnfs/' + external_vnf_id, 'X-Auth-Token' => catalogue.token
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
  delete '/:external_vnf_id' do |external_vnf_id|
    # Forward request to VNF Catalogue
    begin
      response = RestClient.delete catalogue.host + '/vnfs/' + external_vnf_id, 'X-Auth-Token' => catalogue.token
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

end
