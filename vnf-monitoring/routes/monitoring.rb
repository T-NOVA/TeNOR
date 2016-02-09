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

  before do

    if request.path_info == '/gk_credentials'
      return
    end

    if settings.environment == 'development'
      return
    end

    authorized?
  end

  # @method post_vnf-monitoring
  # @overload post '/vnf-monitoring/:vnfi_id/monitoring-parameters'
  # Recevie the parameters to monitor given a vnfi_id
  post '/vnf-monitoring/:vnfi_id/monitoring-parameters' do
    return 415 unless request.content_type == 'application/json'

    @json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.error @json

    @json['vnfi_id'] = params['vnfi_id']

    MonitoringMetric.new(@json)

    subscribe = {
        :types => [@json['name']],
        :instances => [params["vnfi_id"]],
        :interval => 1,
        :callbackUrl => settings.vnf_manager + "/vnf-monitoring/" + params['vnfi_id'] + "/readings"
    }
    logger.debug subscribe.to_json
    begin
      RestClient.post settings.vim_monitoring + "/api/subscriptions", subscribe.to_json, :content_type => :json, :accept => :json
    rescue
      halt 400, "VIM Monitoring Module not available"
    end

    return 200
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
  post '/vnf-monitoring/:vnfi_id/readings' do
    logger.error "readings"
    return 415 unless request.content_type == 'application/json'
    json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.debug json.to_json

    json.each do |instance|
      instance['measurements'].each do |measurement|
        monitoringMetric = MonitoringMetric.find_by(:vnfi_id => params[:vnfi_id])
        #store recevied data in Cassandra DB
        metrics = {measurement['type'] => measurement['value'].to_s}
        RestClient.post settings.vnf_monitor_db + '/vnf-monitoring/' + params[:vnfi_id], metrics.to_json, :content_type => :json, :accept => :json

        #send enriched data to NS-Monitoring
        enriched = {
            :parameter_id => monitoringMetric['parameter_id'],
            :value => measurement['value'],
            :timestamp => measurement['timestamp']
        }
        RestClient.post settings.ns_monitor_db + '/ns-monitoring/vnf-instance-readings/' + params[:vnfi_id], enriched.to_json, :content_type => :json, :accept => :json
      end
    end
  end
end