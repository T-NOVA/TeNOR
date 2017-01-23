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
# @see NsProvisioner
class NsProvisioner < TnovaManager

  # @method post_ns_instances
  # @overload post "/ns-instances"
  # Post a ns-instance
  post '/' do

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
    halt 500, errors if errors

    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get NSD by id
    begin
      nsd = RestClient.get catalogue.host + '/network-services/' + instantiation_info['ns_id'].to_s, 'X-Auth-Token' => catalogue.token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.info "Instantiating a new service: " + instantiation_info.to_s

    pop_list = []
    mapping_info = {}
    if instantiation_info['pop_id'].nil? && instantiation_info['vnf_pop'].nil?
      available_pops = getDcs()
      if available_pops.empty?
        halt 400, "No PoPs registereds."
      end
      if !instantiation_info['mapping_id'].nil?
        #using the Mapping algorithm specified in the instantiation request
        mapping = ServiceConfigurationHelper.get_module_by_id(instantiation_info['mapping_id'])
        mapping_info = mapping.host + ":" + mapping.port.to_s + mapping.path
        pop_list = available_pops
      elsif pop_list.size > 1
        #using the first mapping algorithm
        mapping, errors = ServiceConfigurationHelper.get_module_by_type('mapping')
        mapping_info = mapping.host + ":" + mapping.port.to_s + mapping.path
        pop_list = available_pops
      else
        #deploy to the unic PoP
        pop_list << getDc(available_pops[0]['id'])
      end
    elsif !instantiation_info['vnf_pop'].nil?
      instantiation_info['vnf_pop'].each_pair do |key, value|
        pop_list << getDc(value)
      end
    else
      #deploying the Instance into the requested PoP
      pop_list << getDc(instantiation_info['pop_id'])
    end

    infr_repo_url, errors = ServiceConfigurationHelper.get_module_by_type('infr_repo')
    infr_repo_url = nil if errors

    provisioning = {
        :nsd => JSON.parse(nsd),
        :customer_id =>  instantiation_info['customer_id'],
        :nap_id =>  instantiation_info['nap_id'],
        :callback_url => instantiation_info['callbackUrl'],
        :flavour => instantiation_info['flavour'],
        :pop_list => pop_list,
        :mapping => mapping_info,
        :infr_repo_url => infr_repo_url,
        :vnf_mapping => instantiation_info['vnf_pop']
      }
    begin
      response = RestClient.post provisioner.host + request.fullpath, provisioning.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug "Instantiation in process..."
    updateStatistics('ns_instantiated_requests')
    return response.code, response.body
  end

  # @method get_ns_instances_id
  # @overload get "/ns-instances/:nsr_id"
  # Get a ns-instance
  # @param [string] nsr_id Instance id
  get "/:nsr_id" do
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + request.fullpath, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method put_ns_instances
  # @overload put "/ns-instances/:nsr_id"
  # Update a ns-instance
  # @param [string] nsr_id Instance id
  put '/:nsr_id' do
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.put provisioner.host + request.fullpath, request.body.read, 'X-Auth-Token' => provisioner.token, :content_type => :json
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
  # @overload get "/ns-instances/:nsr_id/status"
  # Get a ns-instance status
  # @param [string] nsr_id Instance id
  get '/:nsr_id/status' do
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + request.fullpath, 'X-Auth-Token' => provisioner.token, :content_type => :json
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
  get '/' do
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + request.fullpath, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method put_ns_instances
  # @overload put "/ns-instances/:nsr_id/:status"
  # Update ns-instance status
  # @param [string] nsr_id Instance id
  # @param [string] status Status
  put '/:nsr_id/:status' do
    logger.info "Change status request of " + params[:nsr_id].to_s + " to " + params[:status].to_s
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + '/ns-instances/' + params[:nsr_id].to_s, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    nsr, errors = parse_json(response)

    #get DCs info of this NSR
    pop_info = []
    nsr['vnfrs'].each do |vnfr|
      pop_info << getDc(vnfr['pop_id'].to_i)
    end

    begin
      response = RestClient.put provisioner.host + request.fullpath, {pop_info: pop_info}.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

	if params[:status] == 'terminate'
	    updateStatistics('ns_terminated_requests')
	end

    return response.code, response.body
  end

  # @method delete_ns_instances
  # @overload delete "/ns-instances/:nsr_id"
  # Delete a ns-instance
  # @param [string] nsr_id Instance id
  delete '/:nsr_id' do |nsr_id|
    logger.info "Delete executed for NSR: #{nsr_id.to_s}"
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + request.fullpath.to_s, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    nsr, errors = parse_json(response)

    #get DCs info of this NSR
    pop_info = []
    nsr['vnfrs'].each do |vnfr|
      pop_info << getDc(vnfr['pop_id'].to_i)
    end

    logger.info "Sending terminate request to NS Provisioning"
    begin
      response = RestClient.put provisioner.host + request.fullpath.to_s + '/terminate', {pop_info: pop_info}.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_terminated_requests')

    return response.code, response.body
  end

  # @method post_ns_instances_id_instantiate
  # @overload post "/ns-instances/:nsr_id/instantiate"
  # Callback response of instantiation request. This method is called by the VNFManager.
  # @param [string] nsr_id Instance id
  post '/:nsr_id/instantiate' do |nsr_id|

    callback_response, errors = parse_json(request.body.read)

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + '/ns-instances/' + nsr_id, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    nsr, error = parse_json(response)

    catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
    halt 500, errors if errors

    begin
      response = RestClient.get catalogue.host + '/network-services/' + nsr['nsd_id'], 'X-Auth-Token' => catalogue.token, :content_type => :json
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

    info = { :callback_response => callback_response, :nsd => nsd }
    begin
      response = RestClient.post provisioner.host + request.fullpath, info.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
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
