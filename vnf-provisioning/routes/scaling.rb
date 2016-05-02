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
# @see OrchestratorVnfProvisioning
class OrchestratorVnfProvisioning < Sinatra::Application

  post "/vnf-instances/scaling/:vnfr_id/scale_out" do

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

  post "/vnf-instances/scaling/:vnfr_id/scale_in" do

    scaled_resources = "http://www.example.com"

    auth_token = "aaa"

    puts "Send DELETE to: "
    puts scaled_resources


    begin
      response = RestClient.get scaled_resources, 'X-Auth-Token' => auth_token, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue RestClient::ResourceNotFound
      puts "Already removed from the VIM."
    rescue => e
      puts e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    puts response
    return

    #get the scale_scale information in the VNFR
    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error 'VNFR record not found'
      halt 404
    end

    scaled_resources = vnfr['vdu'].detect { |vdu| vdu['type'] == 1 }

    scaled_resources['stack_url'] = "http://localhost/stackurl"

    puts scaled_resources['stack_url']

    begin
      response = RestClient.delete scaled_resources['stack_url'], 'X-Auth-Token' => auth_token, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue RestClient::ResourceNotFound
      puts "Already removed from the VIM."
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    vnfr['vdu'].delete_if { |x| x['id'] == scaled_resources['id'] }

    halt 200, "Scale in done."
  end

  post "/test" do

    vnfr = Vnfr.create({})

    return vnfr
  end

end