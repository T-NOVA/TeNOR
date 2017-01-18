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
class NsScaling < TnovaManager

  # @method post_ns_instances_scaling_out
  # @overload post "/ns-instances/scaling/:nsr_id/scale_out"
  # Manual scaling out given ns instance id
  # @param [string] nsr_id NS instance id
  post '/:nsr_id/scale_out' do |nsr_id|

    return 415 unless request.content_type == 'application/json'

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.post provisioner.host + "/ns-instances/scaling/#{nsr_id}/scale_out", "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.info response.code

    updateStatistics('ns_scaling_out_requests')

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

    begin
      response = RestClient.post provisioner.host + "/ns-instances/scaling/#{nsr_id}/scale_in", "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.info response.code

    updateStatistics('ns_scaling_in_requests')

    return response.code, response.body
  end

  # @method post_ns_instances_auto_scale
  # @overload post "/ns-instances/scaling/:nsr_id/auto_scale"
  # Autoscaling a Network service given a SLA breach in the monitoring
  # @param [string] nsr_id NS instance id
  post '/:nsr_id/auto_scale' do |nsr_id|
    logger.debug "#{nsr_id}: Request for AUTO SCALE"

    return 415 unless request.content_type == 'application/json'

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    updateStatistics('SLA_breaches')

    # Validate JSON format
    auto_scale_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      nsr, errors = parse_json(RestClient.get provisioner.host + '/ns-instances/' + nsr_id, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.debug "#{nsr_id}: Breach detected of parameter: #{auto_scale_info['parameter_id'].to_s}"

    flavour = nsr['service_deployment_flavour']
    halt 500, "Flavour not found for autoscale." if flavour.nil?
    halt 500, "No autoscale policy for flavour: #{flavour}." if nsr['auto_scale_policy'][flavour].nil?

    auto_scale_policy = nsr['auto_scale_policy'][flavour].find { |as| as['criteria'][0]['assurance_parameter_id'] == auto_scale_info['parameter_id'].to_s }
    halt 500, "No autoscale policy for flavour with this parameter." if auto_scale_policy.nil?

    #if auto_scale_policy
    if auto_scale_policy['actions'][0]['type'] == "Scale Out"
      event = "scale_out"
    elsif auto_scale_policy['actions'][0]['type'] == "Scale In"
      event = "scale_in"
    else
      halt 400, "No event defined for this scale request."
    end

    logger.info "#{nsr_id}: Executing a #{event}"

    begin
      response = RestClient.post provisioner.host + "/ns-instances/scaling/#{nsr_id}/#{event}", "", 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('auto_scaling_request_executed')

    logger.debug "#{nsr_id}: autoScaling executed."
    return response.code, response.body
  end

end
