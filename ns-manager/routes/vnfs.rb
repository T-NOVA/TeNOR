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
# @see VNFManager
class VNFCatalogueController < TnovaManager

  # @method get_vnfs
  # @overload get "/vnfs"
  # Get the VNFs list
  get '/' do
    begin
      @service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method get_vnfs
  # @overload get "/vnfs/:vnf_id"
  # Get specific VNF
  # @param [string]
  get '/:vnf_id' do
    begin
      @service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method post_vnfs
  # @overload post "/vnfs"
  # Post a new VNF
  post '/' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    #updateStatistics('vnfs_created_requests')
    return response.code, response.body

  end

  # @method put_vnfs
  # @overload put "/vnfs/:vnf_id"
  # Update a VNF
  # @param [string]
  put '/:vnf_id' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method delete_vnfs
  # @overload delete "/vnfs/:vnf_id"
  # Delete a VNFs
  # @param [string]
  delete '/:vnf_id' do

    #check if some NSD is using it

    begin
      @service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Catalogue Microservice unrechable."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/network-services/vnf/' + params[:vnf_id].to_s, 'X-Auth-Token' => @client_token, :content_type => :json
      nss, errors = parse_json(response)
      if nss.size > 0
        halt 400, nss.size + 'Network Services are using this VNF.'
      end
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      #halt e.response.code, e.response.body
      logger.error "Any network service is using this VNF."
    end

    begin
      @service = ServiceModel.find_by(name: "vnf_manager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "VNF Manager Microservice unrechable."
    end

    begin
      response = RestClient.delete @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end