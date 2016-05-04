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
# @see TnovaManager
class MonitoringController < TnovaManager

  # @method get_accounting_servicestatus
  # @overload get '/accounting/servicestatus/:ns_instance_id/:status'
  # Get network service status
  # @param [string]
  put '/accounting/servicestatus/:ns_instance_id/:status' do

    begin
      @service = ServiceModel.find_by(name: "ns_provisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      puts e.response
      #logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method get_instances_monitoring_data
  # @overload get '/instances/:instance_id/monitoring-data/'
  # Get monitoring data given instance type and/or metrics
  # @param [string] instance_type
  # @param [string] instance_id
  # @param [string] metric
  get '/instances/:instance_id/monitoring-data/' do
    logger.debug params
    logger.debug request.fullpath
    if params['instance_type'] == 'ns'
      begin
        @service = ServiceModel.find_by(name: "ns_monitoring")
      rescue Mongoid::Errors::DocumentNotFound => e
        halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
      end
      composedUrl = "/ns-monitoring/"+params['instance_id'].to_s+"/monitoring-data/?"+request.env['QUERY_STRING']
    elsif params['instance_type'] == 'vnf'
      begin
        @service = ServiceModel.find_by(name: "vnf_manager")
      rescue Mongoid::Errors::DocumentNotFound => e
        halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
      end
      composedUrl = "/vnf-monitoring/"+params['instance_id'].to_s+"/monitoring-data/?"+request.env['QUERY_STRING']
    end

    if (params["metric"])
      #composedUrl = composedUrl + "/" + params["metric"]
    end
    logger.debug composedUrl
    logger.debug @service.host.to_s + ":" + @service.port.to_s + composedUrl.to_s
    begin
      response = RestClient.get @service.host.to_s + ":" + @service.port.to_s + composedUrl.to_s, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Monitoring unreachable'
    rescue => e
      halt e.response.code, e.response.body
    end
    #return response.code, response.body
    return 200, response.body
  end

  #/instances/:instance_id/monitoring-data/?instance_type=ns&metric
=begin
  {
      "nsi_id": "123",
      "external_parameter_id": "987",
      "value": "10.5"
  }
=end
  post '/ns-manager/sla-breaches' do

  end

  # @method post_vnf_instance_readings
  # @overload post '/ns-monitoring/vnf-instance-readings/:vnf_instance_id'
  # Post a vnf monitoring data
  # @param [string]
  post '/ns-monitoring/vnf-instance-readings/:vnf_instance_id' do

    begin
      @service = ServiceModel.find_by(name: "ns_monitoring")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Monitoring unreachable'
    rescue => e
      puts e
      #logger.error e.response
      #halt e.response.code, e.response.body
    end
    puts response
    return 200
    return response.code, response.body
  end

  # @method get_monitoring_data_last100
  # @overload get '/instances/:instance_id/monitoring-data/last100'
  # Get last 100 values
  # @param [string] Instance id
  get '/instances/:instance_id/monitoring-data/last100/' do

    if params['instance_type'] == 'ns'
      begin
        @service = ServiceModel.find_by(name: "ns_monitoring")
      rescue Mongoid::Errors::DocumentNotFound => e
        halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
      end
      composedUrl = "/ns-monitoring/"+params['instance_id'].to_s+"/monitoring-data/last100/?"+request.env['QUERY_STRING']
    elsif params['instance_type'] == 'vnf'
      begin
        @service = ServiceModel.find_by(name: "vnf_manager")
      rescue Mongoid::Errors::DocumentNotFound => e
        halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
      end
      composedUrl = "/vnf-monitoring/"+params['instance_id'].to_s+"/monitoring-data/last100/?"+request.env['QUERY_STRING']
    end

    logger.debug composedUrl
    logger.debug @service.host.to_s + ":" + @service.port.to_s + composedUrl.to_s
    begin
      response = RestClient.get @service.host.to_s + ":" + @service.port.to_s + composedUrl.to_s, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Monitoring unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response
  end


end