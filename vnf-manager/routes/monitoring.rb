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
# @see VNFManager
class Monitoring < VNFManager

  # @method post_vnf_monitoring_id_parameters
  # @overload post '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  #   Send monitoring info to VNF Monitoring
  #   @param [Integer] vnfi_id the VNF Instance ID
  # Send monitoring info to VNF Monitoring
  post '/:vnfr_id/monitoring-parameters' do |vnfr_id|

    provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
    halt 500, errors if errors

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
    halt 500, errors if errors

    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    monitoring_info = parse_json(request.body.read)
    #vnfr_id = monitoring_info['vnfr_id']

    begin
      response = RestClient.get provisioner.host + "/vnf-provisioning/vnf-instances/" + vnfr_id, 'X-Auth-Token' => provisioner.token, :content_type => :json, :accept => :json
    rescue
      halt 400, "VIM Monitoring Module not available"
    end
    vnfr, errors = parse_json(response)
    return 400, errors.to_json if errors

    begin
      response = RestClient.get catalogue.host + "/vnfs/" + vnfr['vnfd_reference'], 'X-Auth-Token' => catalogue.token, :content_type => :json, :accept => :json
    rescue
      halt 400, "VNF Catalogue not available"
    end
    vnfd, errors = parse_json(response)
    return 400, errors.to_json if errors

    monitoring_info['vnfr'] = vnfr
    monitoring_info['vnfd'] = vnfd

    # Forward the request to the VNF Monitoring
    begin
      response = RestClient.post monitoring.host + "/vnf-monitoring/#{vnfr_id}/monitoring-parameters", monitoring_info.to_json, 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method post_vnf_monitoring_id_readings
  # @overload post '/vnf-monitoring/:vnfr_id/readings'
  # Recevie monitoring data
  # @param [Integer] vnfr_id the VNF Instance ID
  post '/:vnfr_id/readings' do |vnfr_id|

    provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
    halt 500, errors if errors

    monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
    halt 500, errors if errors

    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    monitoring_info = parse_json(request.body.read)

    begin
      response = RestClient.get provisioner.host + "/vnf-provisioning/vnf-instances/" + vnfr_id, 'X-Auth-Token' => provisioner.token, :content_type => :json, :accept => :json
    rescue RestClient::NotFound => e
      puts e
      puts e.response
      logger.debug "This VNF instance no exists. Getting list of subscriptions in order to get the Subscription ID."

      begin
        response = RestClient.delete monitoring.host + "/vnf-monitoring/subscription/" + vnfr_id, 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
      rescue => e
        logger.error e
        logger.error "Error removing subscription"
        halt 400, "Error removing subscription"
      end
      halt 200, "Removed subscription because the VNFR is not defined."
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
      halt 400, "VIM Provisioning Module not available"
    end
    vnfr, errors = parse_json(response)
    return 400, errors.to_json if errors

    # Forward the request to the VNF Monitoring
    begin
      response = RestClient.post monitoring.host + "/vnf-monitoring/#{vnfr_id}/readings", monitoring_info.to_json, 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method get_monitoring_data
  # @overload get '/vnf-monitoring/:vnfi_id/monitoring-data/'
  #	Get monitoring data
  #	@param [Integer] instance_id
  get '/:vnfi_id/monitoring-data/' do |vnfi_id|

    monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
    halt 500, errors if errors

    path = request.fullpath

    # if vdui id is null, search in the vnfr the vdus ids
    if params['vduid'].nil?
      provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
      halt 500, errors if errors

      begin
        response = RestClient.get provisioner.host + "/vnf-provisioning/vnf-instances/" + vnfi_id, 'X-Auth-Token' => provisioner.token, :content_type => :json, :accept => :json
      rescue RestClient::NotFound => e
        puts e
        puts e.response
        logger.debug "This VNF instance no exists. Getting list of subscriptions in order to get the Subscription ID."
      end
      halt 404 if response.nil

      vms = ""
      response['vms'].each do |vm|
        vms = "&vdus[]=" + vm['physical_resource_id'].to_s
        path = path + vms
      end
    end

    # Forward the request to the VNF Monitoring
    begin
      response = RestClient.get monitoring.host + path, 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method get_monitoring_data_100
  # @overload get '/vnf-monitoring/:vnfi_id/monitoring-data/last100'
  #	Get monitoring data, last 100 values
  #	@param [Integer] instance_id
  get '/:vnfi_id/monitoring-data/last100/' do

    monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
    halt 500, errors if errors

    begin
      response = RestClient.get monitoring.host + request.fullpath, 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method delete_monitoring_data
  # @overload delete '/vnf-monitoring/:vnfi_id/monitoring-data/last100'
  #	Delete subscription and monitoring info
  #	@param [Integer] instance_id
  delete '/:vnfr_id/monitoring-data' do |vnfr_id|

    monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
    halt 500, errors if errors

    begin
      response = RestClient.delete "#{settings.vnf_monitoring}/vnf-monitoring/subscription/#{vnfr_id}", 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error "ERRORORRR"

      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

end
