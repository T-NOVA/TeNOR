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

  # @method post_vnf_monitoring
  # @overload post '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  # Recevie the parameters to monitor given a vnfi_id
  post '/vnf-monitoring/:vnfr_id/monitoring-parameters' do
    return 415 unless request.content_type == 'application/json'

    @json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.debug @json

    @json['vnfr_id'] = params['vnfr_id']
    vnfd = @json['vnfd']
    @json.delete('vnfd')
    vnfr = @json['vnfr']#should not being saved
    #@json.delete('vnfr')

    puts "VNFR:"
    puts @json['vnfr']

    MonitoringMetric.new(@json).save!

    types = []
    instances = []
    vnfd['vnfd']['vdu'].each do |vdu|
      vdu['monitoring_parameters'].each do |mP|
        types.push(mP['metric'])
      end
      vdu['monitoring_parameters_specific'].to_a.each do |mP|
        types.push(mP['metric'])
      end

    end
    @json['vnfr']['vms_id'].each { |key, value| instances << value }

    puts "Creating subcription message"
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

    logger.debug subscription_response

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
  #curl http://10.10.1.61:4567/vnf-monitoring/5730bdfdb18cfb5a82000003/readings -H "Content-Type: application/json" -d '[{"instance": "cc58b58f-d38c-48b6-8e83-d238bea0568e", "measurements": [{"timestamp": "1970-01-01T00:00:00Z", "value": 197742, "units": "jiffies", "type": "cpuidle"}]}]'
  # @method post_vnf_monitoring_readings
  # @overload post '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  # Receive the monitoring parameters
  post '/vnf-monitoring/:vnfr_id/readings' do
    logger.info "Readings from Monitoring VIM"
    return 415 unless request.content_type == 'application/json'
    json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    vnfr_id = params['vnfr_id'].to_s
    #get RabbitMQ channel information
    ch = settings.channel

    json.each do |instance|
      metrics = []
      instance['measurements'].each do |measurement|
        puts measurement['units']
        metric = {
            :instance_id => vnfr_id,
            :type => measurement['type'],
            :value => measurement['value'],
            :unit => measurement['units'],
            :timestamp => Time.parse(measurement['timestamp']).to_i
        }
        metrics.push(metric)

        q = ch.queue(params['vnfr_id'])
        q.publish(metric.to_json, :persistent => true)

        q = ch.queue("vnf_repository")
        q.publish(metric.to_json, :persistent => true)
      end

      return 200

      #to remove
      begin
        respone = RestClient.post settings.vnf_instance_repository + '/vnf-monitoring/' + vnfr_id, metrics.to_json, :content_type => :json, :accept => :json
      rescue => e
        puts e
        puts "Error saving values to Cassandra."
      end

      begin
        RestClient.post settings.ns_manager + '/ns-monitoring/vnf-instance-readings/' + vnfr_id, metrics.to_json, :content_type => :json, :accept => :json
      rescue => e
        puts e
        puts "Error with sending the values to the NS Monitoring."
      end
    end
    return 200
  end

  # @method get_monitoring_data
  # @overload delete '/vnf-monitoring/:instance_id/monitoring-data/last'
  #	Get monitoring data, last 100 values
  #	@param [Integer] instance_id
  get '/vnf-monitoring/:instance_id/monitoring-data/' do
    begin
      response = RestClient.get settings.vnf_instance_repository + request.fullpath, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

  # @method get_monitoring_data_100
  # @overload delete '/vnf-monitoring/:instance_id/monitoring-data/last100'
  #	Get monitoring data, last 100 values
  #	@param [Integer] instance_id
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