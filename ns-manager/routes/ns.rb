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
class NsCatalogue < TnovaManager

  # @method get_network_services
  # @overload get "/network-services"
  # Get the Network Service list
  get '/' do

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method get_network_services_id
  # @overload get "/network-services/:id"
  # Get a Network Service
  # @param [string] id Network service id
  get '/:id' do

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method post_network_services
  # @overload post "/network-services"
  # Save a new Network Service
  post '/' do

    # Validate JSON format
    ns, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    # Validate NS
    return 400, 'ERROR: NSD not found' unless ns.has_key?('nsd')

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Catalogue Microservice unrechable."
    end

    begin
      @vnf_service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "VNF Catalogue Microservice unrechable."
    end

    #check if the VNFDs defined in the NSD are defined
    ns['nsd']['vnfds'].each do |vnf|
      begin
        logger.error "Check VNFD " + vnf
        response = RestClient.get @vnf_service.host + ":" + @vnf_service.port.to_s + '/vnfs/' + vnf, 'X-Auth-Token' => @client_token, :content_type => :json
      rescue Errno::ECONNREFUSED
        halt 500, 'VNF Catalogue unreachable'
      rescue => e
        logger.error "VNFD not defined."
        logger.error e.response
        halt e.response.code, e.response.body
      end
    end

    begin
      response = RestClient.post  @service.host + ":" + @service.port.to_s + request.fullpath, ns.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_created_requests')

    return response.code, response.body

  end

  # @method put_network_services
  # @overload put "/network-services/:id"
  # Update a new Network Service
  # @param [string] id Network service id
  put '/:external_ns_id' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put  @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method delete_network_services
  # @overload delete "/network-services/:id"
  # Delete a new Network Service
  # @param [string] id Network service id
  delete '/:external_ns_id' do

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.delete  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end
