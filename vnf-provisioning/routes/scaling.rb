#
# TeNOR - VNF Provisioning
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
# @see VnfProvisioning
class Scaling < VnfProvisioning

  # @method post_vnf_instances_scale_out
  # @overload post '/vnf-instances/scaling/:id/scale_out'
  # Post a Scale out request
  # @param [JSON]
  post "/:vnfr_id/scale_out" do

    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    scale_info = parse_json(request.body.read)
    #logger.debug 'Scale out: ' + scale_info.to_json
    halt 400, 'NS Manager callback URL not found' unless scale_info.has_key?('vnfd')

    vnfr = scale_info['vnfr']

    logger.error vnfr
    logger.info vnfr['scale_resources']
    logger.info scale_info['auth']

    vnfr['scale_resources'].each do |resource|
      logger.info resource
      logger.info resource['id']
      logger.debug "Sending request to Openstack for Scale OUT"
      begin
        response = parse_json(RestClient.post resource['scale_out'], "", :accept => :json)
      rescue Errno::ECONNREFUSED
        halt 500, 'VIM unreachable'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end
      logger.debug "Scale out ok."

      logger.info "Authentication to VIM"
      vim_info = vnfr['auth']
      token_info = request_auth_token(vim_info)
      tenant_id = token_info['access']['token']['tenant']['id']
      auth_token = token_info['access']['token']['id']

      #get stack of AutoScalingGroup
      begin
        response = parse_json(RestClient.get "#{vim_info['heat']}/#{tenant_id}/stacks/#{resource['id']}", 'X-Auth-Token' => auth_token, :accept => :json)
      rescue Errno::ECONNREFUSED
        halt 500, 'VIM unreachable'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end

      logger.info "GET AutoscalingGroup stack:"
      logger.info response
      stack_id = response['stack']['id']

      #get instances of the scaling group
      begin
        response = parse_json(RestClient.get "#{vim_info['heat']}/#{tenant_id}/stacks/#{resource['id']}/#{stack_id}/resources", 'X-Auth-Token' => auth_token, :accept => :json)
      rescue Errno::ECONNREFUSED
        halt 500, 'VIM unreachable'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end

      logger.info "GET Resources of AutoscalingGroup stack:"
      logger.info response

      response['resources'].each do |res|
        logger.info res['physical_resource_id']
        logger.info res['resource_name']
      end

      logger.info "Execute lifecycle events"



    end


    logger.info "Lifecycle events..."
    logger.info vnfr['lifecycle_info']
    logger.info vnfr['lifecycle_info']['events']

    halt 200, "Scale out ok"
  end



  # @method post_vnf_instances_scale_out
  # @overload post '/vnf-instances/scaling/:id/scale_out'
  # Post a Scale out request
  # @param [JSON]
  post "/:vnfr_id/scale_out_old" do

    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    scale_info = parse_json(request.body.read)
    logger.debug 'Instantiation info: ' + scale_info.to_json
    halt 400, 'NS Manager callback URL not found' unless scale_info.has_key?('vnfd')

    vnfd = scale_info['vnfd']

    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error 'VNFR record not found'
      halt 404
    end

    logger.debug "Generating new hot template for the new VDUs"

    hot_generator_message = {
        vnf: vnf,
        networks_id: instantiation_info['networks'],
        security_group_id: instantiation_info['security_group_id']
    }
    begin
      hot = parse_json(RestClient.post settings.hot_generator + '/scale_hot/' + vnf_flavour, hot_generator_message.to_json, :content_type => :json, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'HOT Generator unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    #send hot to VIM
    response = provision_vnf(vim_info, vnf['name'] +"_scale_out_" + SecureRandom.hex, hot)
    logger.debug 'Provision response: ' + response.to_json

    #save stack_scale info to VNRF
    resource = {}
    resource['stack_url'] = response['stack']['links'][0]['href']
    resource['id'] = response['stack']['id']
    resource['type'] = 1

    vnfr['vdu'] << resource
    #the value is saved?

    halt 200, "Scale out done."

  end

  # @method post_vnf_instances_scale_in
  # @overload post '/vnf-instances/scaling/:id/scale_in'
  # Post a Scale in request
  # @param [JSON]
  post "/:vnfr_id/scale_in" do

    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    scale_info = parse_json(request.body.read)
    logger.debug 'Scale out: ' + scale_info.to_json
    halt 400, 'NS Manager callback URL not found' unless scale_info.has_key?('vnfd')

    vnfr = scale_info['vnfr']

    logger.debug "Sending request to Openstack for Scale OUT"
    begin
      response = parse_json(RestClient.post vnfr['scale_info']['scale_out'], "", :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug "Scale out ok."

    #reading information from the VIM about the stack.

    logger.debug "Response is null."


    halt 200, "Scale in done."
  end

end