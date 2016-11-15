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
# @see NsScaling
class NsScaling< TnovaManager

  # @method post_ns_instances_scaling_out
  # @overload post "/ns-instances/scaling/:nsr_id/scale_out"
  # Manual scaling out given ns instance id
  # @param [string] nsr_id NS instance id
  post '/:nsr_id/scale_out' do |nsr_id|

    return 415 unless request.content_type == 'application/json'

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors
    catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
    halt 500, errors if errors

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      instantiation_info, errors = parse_json(RestClient.get provisioner.host + '/ns-instances/' + nsr_id, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.error instantiation_info['nsd_id']
    # Get NS by id
    begin
      nsd = RestClient.get catalogue.host + '/network-services/' + instantiation_info['nsd_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    begin
      response = RestClient.post provisioner.host + request.fullpath, "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.error "Scaling correct."
    logger.error response.code

    return response.code, response.body
  end

  # @method post_ns_instances_scaling_in
  # @overload post "/ns-instances/scaling/:nsr_id/scale_in"
  # Manual scaling in given ns instance id
  # @param [string] nsr_id NS instance id
  post '/:nsr_id/scale_in' do |nsr_id|

    return 415 unless request.content_type == 'application/json'

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors
    catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
    halt 500, errors if errors

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      instantiation_info, errors = parse_json(RestClient.get provisioner.host + '/ns-instances/' + nsr_id, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    # Get NS by id
    begin
      nsd = RestClient.get catalogue.host + '/network-services/' + instantiation_info['nsd_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    begin
      response = RestClient.post provisioner.host + request.fullpath, "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.error "Scaling correct."
    logger.error response.code

    return response.code, response.body
  end

  # @method post_ns_instances_auto_scale
  # @overload post "/ns-instances/scaling/:nsr_id/auto_scale"
  # Autoscalin
  # @param [string] nsr_id NS instance id
  post '/:nsr_id/auto_scale' do |nsr_id|
    logger.info "----------------------------------- Request for AUTO SCALE -----------------------------------"

    return 415 unless request.content_type == 'application/json'

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    # Validate JSON format
    auto_scale_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      instantiation_info, errors = parse_json(RestClient.get provisioner.host + '/ns-instances/' + nsr_id, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.info "Breach of parameter: " + auto_scale_info['parameter_id'].to_s

    flavour = instantiation_info['service_deployment_flavour']
    halt 500, "Flavour not found for autoscale." if flavour.nil?
    halt 500, "No autoscale policy for flavour: #{flavour}." if instantiation_info['auto_scale_policy'][flavour].nil?

    auto_scale_policy = instantiation_info['auto_scale_policy'][flavour].find { |as| as['criteria'][0]['assurance_parameter_id'] == auto_scale_info['parameter_id'].to_s }
    halt 500, "No autoscale policy for flavour with this parameter." if auto_scale_policy.nil?

    #if auto_scale_policy
    if auto_scale_policy['actions'][0]['type'] == "Scale Out"
      event = "scale_out"
    elsif auto_scale_policy['actions'][0]['type'] == "Scale In"
      event = "scale_in"
    else
      halt 400, "No event defined for this scale request."
    end

    begin
      response = RestClient.post provisioner.host + "/ns-instances/scaling/#{nsr_id}/#{event}", "", 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.error "AutoScaling executed."
    return response.code, response.body
  end

end
