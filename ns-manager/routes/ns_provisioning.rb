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

    logger.info "INSTANTIATION INFO: " + instantiation_info.to_s
    pop_list = []
    if instantiation_info['pop_id'].nil?
      pop_list = JSON.parse(getDcs())
      if pop_list.empty?
        halt 400, "No PoPs registereds."
      end
    else
      pop_list = []
      pop_list << JSON.parse(getDc(instantiation_info['pop_id']))
    end

    provisioning = {
        :nsd => JSON.parse(nsd),
        :customer_id =>  instantiation_info['customer_id'],
        :nap_id =>  instantiation_info['nap_id'],
        :callback_url => instantiation_info['callbackUrl'],
        :flavour => instantiation_info['flavour'],
        :pop_list => pop_list,
        #:pop_id => instantiation_info['pop_id'],
        #:pop_info => pop_info,
        :mapping_id => instantiation_info['mapping_id']
      }
    begin
      response = RestClient.post provisioner.host + request.fullpath, provisioning.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.info "Instantiation correct."
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
      response = RestClient.get provisioner.host + '/ns-instances/' + params['nsr_id'], 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    ns_instance, error = parse_json(response)

    info = { :instance => ns_instance }
    begin
      response = RestClient.put provisioner.host + request.fullpath, info.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  # @method delete_ns_instances
  # @overload delete "/ns-instances/:nsr_id"
  # Delete a ns-instance
  # @param [string] nsr_id Instance id
  delete '/:nsr_id' do
    logger.info "Delete executed.... " + params[:nsr_id].to_s
    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + '/ns-instances/' + params['nsr_id'], 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    ns_instance, error = parse_json(response)

    logger.info "Sending terminate request to NS Provisioning"
    info = { :instance => ns_instance }
    begin
      response = RestClient.put provisioner.host + request.fullpath.to_s + '/terminate', info.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
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
  # @overload post "/ns-instances/:nsr_id/instantiate"
  # Callback response of instantiation request. This method is called by the VNFManager.
  # @param [string] nsr_id Instance id
  post '/:nsr_id/instantiate' do

    callback_response, errors = parse_json(request.body.read)

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.get provisioner.host + '/ns-instances/' + params['nsr_id'], 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    ns_instance, error = parse_json(response)

    catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
    halt 500, errors if errors

    begin
      response = RestClient.get catalogue.host + '/network-services/' + ns_instance['nsd_id'], 'X-Auth-Token' => catalogue.token, :content_type => :json
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

    info = { :callback_response => callback_response, :instance => ns_instance, :nsd => nsd}
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
