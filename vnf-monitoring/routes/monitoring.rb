#
# TeNOR - VNF Monitoring
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
# @see VNFMonitoring
class VNFMonitoring < Sinatra::Application

  # @method post_vnf-monitoring
  # @overload post '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  # Recevie the parameters to monitor given a vnfi_id
  post '/vnf-monitoring/:vnfr_id/monitoring-parameters' do
    return 415 unless request.content_type == 'application/json'

    @json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.error @json

    @json['vnfr_id'] = params['vnfr_id']
    #@json['vnfr'] = params['vnfr']
    #@json['vnfi_id'] = @json['vnfi_id']
    vnfd = @json['vnfd']
    vnfr = @json['vnfr']

    puts "VNFR:"
    puts @json['vnfr']

    MonitoringMetric.new(@json).save!

    types = []
    instances = []
    vnfd['vnfd']['vdu'].each do |vdu|
      vdu['monitoring_parameters'].each do |mP|
        types.push(mP['metric'])
      end
      vdu['monitoring_parameters_specific'].each do |mP|
        types.push(mP['metric'])
      end

      @json['vnfr'].vms_id.each { |key, value| instances << value }
    end

    puts "Creating subcription message"
    #subscribe
    subscribe = {
        :types => types,
        :instances => instances,
        :interval => 1,
        :callbackUrl => settings.vnf_manager + "/vnf-monitoring/" + params['vnfr_id'] + "/readings"
    }
    logger.debug subscribe.to_json
    begin
      response = RestClient.post settings.vim_monitoring + "/api/subscriptions", subscribe.to_json, :content_type => :json, :accept => :json
    rescue => e
      puts e
      halt 400, "VIM Monitoring Module not available"
    end
    #if(response.status == 200)
    #response.split("under ID ")[1]
    #end
    subscription_response, errors = parse_json(response)
    return 400, errors.to_json if errors

    logger.error subscription_response

    #save subscription id
    #MonitoringMetric

    return 200, subscription_response.to_json
  end


  #store data in VNF-Monitoring-Repository
=begin
   [
  {
    "instance": "27ad39af-0267-4f81-bdc6-deda0d64c9ac",
    "measurements": [
      {
        "timestamp": "1970-01-01T00:00:00Z",
        "value": 197742,
        "units": "jiffies",
        "type": "cpuidle"
      }
    ]
  }
]
=end
  post '/vnf-monitoring/:vnfr_id/readings' do
    logger.error "Readings from Monitoring VIM"
    return 415 unless request.content_type == 'application/json'
    json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    vnfr_id = params['vnfr_id']

    json.each do |instance|
      metrics = []
      enricheds = []
      instance['measurements'].each do |measurement|
        monitoringMetric = MonitoringMetric.find_by(:vnfr_id => params[:vnfr_id])
        #store recevied data in Cassandra DB
        puts monitoringMetric.to_json
        metric = {
            :type => measurement['type'],
            :value => measurement['value'],
            :unit => measurement['unit'],
            :timestamp => Time.parse(measurement['timestamp']).to_i
        }
        metrics.push(metric)

        #if the param is not in the monitoringMetric, not send anything
        enriched = {
            #:parameter_id => monitoringMetric['parameter_id'],
            :type => measurement['type'],
            :value => measurement['value'],
            :unit => measurement['unit'],
            :timestamp => Time.parse(measurement['timestamp']).to_i
        }
        enricheds.push(enriched)
      end

      begin
        respone = RestClient.post settings.vnf_instance_repository + '/vnf-monitoring/' + vnfr_id, metrics.to_json, :content_type => :json, :accept => :json
      rescue => e
        puts e
        puts "Error saving values to Cassandra."
      end

      begin
        RestClient.post settings.ns_manager + '/ns-monitoring/vnf-instance-readings/' + vnfr_id, enricheds.to_json, :content_type => :json, :accept => :json
      rescue => e
        puts e
        puts "Error with sending the values to the NS Monitoring."
      end
    end
    return 200
  end

  #/vnf-monitoring/instances/10/monitoring-data/
  get '/vnf-monitoring/:instance_id/monitoring-data/' do
    begin
      response = RestClient.get settings.vnf_instance_repository + request.fullpath, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

  get '/vnf-monitoring/:instance_id/monitoring-data/last100/' do
    begin
      response = RestClient.get settings.vnf_instance_repository + request.fullpath, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

end