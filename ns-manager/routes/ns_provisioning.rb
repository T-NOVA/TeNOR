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
# @see NsProvisionerController
class NsProvisionerController < TnovaManager

  # @method post_ns_instances
  # @overload post "/ns-instances"
  # Post a ns-instance
  post '/' do

    popList = getPopList()
    if popList.empty?
      halt 400, "No PoPs registereds."
    end

    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    begin
      @service_ns_catalogue = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    # Get VNF by id
    begin
      nsd = RestClient.get @service_ns_catalogue.host + ":" + @service_ns_catalogue.port.to_s + '/network-services/' + instantiation_info['ns_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    provisioning = {:nsd => JSON.parse(nsd), :customer_id => "some_id", :nap_id => "some_id", :callback_url => instantiation_info['callbackUrl'], :flavour => instantiation_info['flavour'], :pop_list => popList, :pop_id => instantiation_info['pop_id'] }

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, provisioning.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.error "Instantiation correct."
    updateStatistics('ns_instantiated_requests')
    return response.code, response.body
  end

  # @method get_ns_instances_id
  # @overload get "/ns-instances/:ns_instance_id"
  # Get a ns-instance
  # @param [string] Instance id
  get "/:ns_instance_id" do
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method put_ns_instances
  # @overload put "/ns-instances/:ns_instance_id"
  # Update a ns-instance
  # @param [string] Instance id
  put '/:ns_instance_id' do
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_updated_requests')
    updateStatistics('ns_terminated_requests')

    return response.code, response.body
  end

  # @method get_ns_instance_status
  # @overload get "/ns-instances/:ns_instance_id/status"
  # Get a ns-instance status
  # @param [string] Instance id
  # @param [string] Status
  get '/:ns_instance_id/status' do
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method get_ns_instances
  # @overload get "/ns-instances"
  # Get all ns-instances
  # @param [string]
  get '/' do
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method put_ns_instances
  # @overload put "/ns-instances/:ns_instance_id/:status"
  # Update ns-instance status
  # @param [string] Instance id
  # @param [string] Status
  put '/:ns_instance_id/:status' do
    logger.info "Change status request of " + params[:ns_instance_id].to_s + " to " + params[:status].to_s
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['ns_instance_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    @ns_instance, error = parse_json(response)

    info = { :instance => @ns_instance }
    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method delete_ns_instances
  # @overload delete "/ns-instances/:id"
  # Delete a ns-instance
  # @param [string] Instance id
  delete '/:ns_instance_id' do
    logger.info "Delete executed.... " + params[:ns_instance_id].to_s
    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['ns_instance_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    @ns_instance, error = parse_json(response)

    logger.info "Sending terminate request to NS Provisioning"
    info = { :instance => @ns_instance }
    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath.to_s + '/terminate', info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.info "Calling NS Provisioner done..."

    updateStatistics('ns_terminated_requests')

    return response.code, response.body
  end

  # @method post_ns_instances_id_instantiate
  # @overload post "/ns-instances/:ns_instance_id/instantiate"
  # Callback response of instantiation request. This method is called by the VNFManager.
  # @param [string]
  post '/:ns_instance_id/instantiate' do

    callback_response, errors = parse_json(request.body.read)

    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['ns_instance_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    @ns_instance, error = parse_json(response)

    begin
      @ns_catalogue_service = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @ns_catalogue_service.host + ":" + @ns_catalogue_service.port.to_s + '/network-services/' + @ns_instance['nsd_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      if e.response == nil
        halt 500, {'Content-Type' => 'text/plain'}, "Error getting the NSD: " + e.to_s
      end
      logger.error e.response
      halt e.response.code, e.response.body
    end
    nsd, error = parse_json(response)

    info = { :callback_response => callback_response, :instance => @ns_instance, :nsd => nsd}
    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_instantiated_requests_ok')

    return response.code, response.body
  end

end