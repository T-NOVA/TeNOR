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
  # @overload get '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  #   Send monitoring info to VNF Monitoring
  #   @param [Integer] vnfi_id the VNF Instance ID
  # Send monitoring info to VNF Monitoring
  post '/:vnfr_id/monitoring-parameters' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    monitoring_info = parse_json(request.body.read)
    vnfr_id = params['vnfr_id']

    #vnfr_id = monitoring_info['vnfr_id']

    begin
      response = RestClient.get settings.vnf_provisioning + "/vnf-provisioning/vnf-instances/" + vnfr_id, :content_type => :json, :accept => :json
    rescue
      halt 400, "VIM Monitoring Module not available"
    end
    vnfr, errors = parse_json(response)
    return 400, errors.to_json if errors

    begin
      response = RestClient.get settings.vnf_catalogue + "/vnfs/" + vnfr['vnfd_reference'], :content_type => :json, :accept => :json
    rescue
      halt 400, "VNF Catalogue not available"
    end
    vnfd, errors = parse_json(response)
    return 400, errors.to_json if errors

    monitoring_info['vnfr'] = vnfr
    monitoring_info['vnfd'] = vnfd
    puts monitoring_info

    # Forward the request to the VNF Monitoring
    begin
      response = RestClient.post "#{settings.vnf_monitoring}/vnf-monitoring/#{params[:vnfr_id]}/monitoring-parameters", monitoring_info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method post_vnf_monitoring_id_readings
  # @overload get '/vnf-monitoring/:vnfi_id/readings'
  # Recevie monitoring data
  # @param [Integer] vnfi_id the VNF Instance ID
  post '/:vnfi_id/readings' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    monitoring_info = parse_json(request.body.read)

    # Forward the request to the VNF Monitoring
    begin
      #vnf-monitoring/:vnfi_id/readings
      response = RestClient.post "#{settings.vnf_monitoring}/vnf-monitoring/#{params[:vnfi_id]}/readings", monitoring_info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
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
  get '/:vnfi_id/monitoring-data/' do
    # Forward the request to the VNF Monitoring
    begin
      response = RestClient.get "#{settings.vnf_monitoring}" + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method get_monitoring_data_100
  # @overload delete '/vnf-monitoring/:vnfi_id/monitoring-data/last100'
  #	Get monitoring data, last 100 values
  #	@param [Integer] instance_id
  get '/:vnfi_id/monitoring-data/last100/' do
    begin
      response = RestClient.get "#{settings.vnf_monitoring}" + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

end