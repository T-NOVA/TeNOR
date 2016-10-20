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
    post '/vnf-monitoring/:vnfr_id/monitoring-parameters' do |vnfr_id|
        return 415 unless request.content_type == 'application/json'

        @json, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        @json['vnfr_id'] = vnfr_id
        vnfd = @json['vnfd']

        logger.info 'VNFR: '
        logger.debug @json['vnfr']

        types = []
        instances = []
        @json['vnfd']['vnfd']['vdu'].each do |vdu|
            vdu['monitoring_parameters'].each do |mP|
                types.push(mP['metric']) unless types.include?(mP['metric'])
            end
            vdu['monitoring_parameters_specific'].to_a.each do |mP|
                types.push(mP['metric']) unless types.include?(mP['metric'])
            end
        end
        @json['vnfr']['vms_id'].each { |_key, value| instances << value }

        logger.info 'Creating subcription message'
        callbackUrl = settings.vnf_manager + '/vnf-monitoring/' + params['vnfr_id'] + '/readings'
        url = 'http://' + callbackUrl unless callbackUrl.include? 'http://'
        subscribe = {
            types: types,
            instances: instances,
            interval: 1,
            callbackUrl: url
        }
        logger.debug subscribe.to_json
        begin
            response = RestClient.post settings.vim_monitoring + '/api/subscriptions', subscribe.to_json, content_type: :json, accept: :json
        rescue => e
            puts e
            halt 400, 'VIM Monitoring Module not available'
        end

        #subscription_response, errors = parse_json(response)
        #return 400, errors.to_json if errors
        #logger.debug subscription_response

        monitoring_info = {
            :vnfr_id => vnfr_id,
            :subcription_id => response.split("under ID ")[1]
        }
        MonitoringMetric.new(monitoring_info).save!

        return 200, monitoring_info.to_json
    end

    delete '/vnf-monitoring/subcription/:vnfr_id' do |vnfr_id|
        begin
            mon_data = MonitoringMetric.find_by(:vnfr_id => vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error "MOnitoring Metric no exists."
            halt 400, 'Sla no exists'
        end
        logger.debug mon_data
        begin
            response = RestClient.delete settings.vim_monitoring + '/api/subscriptions/' + mon_data['subcription_id'], accept: :json
        rescue => e
            puts e
            halt 400, 'VIM Monitoring Module not available'
        end
        mon_data.destroy

        destroy_monitoring_data(vnfr_id)

        halt 200, "Correct unsubcription."
    end

    # store data in VNF-Monitoring-Repository
    #    [
    #   {
    #     "instance": "27ad39af-0267-4f81-bdc6-deda0d64c9ac",
    #     "measurements": [
    #       {
    #         "timestamp": "1970-01-01T00:00:00Z",
    #         "value": 197742,
    #         "units": "jiffies",
    #         "type": "cpuidle"
    #       }
    #     ]
    #   }
    # ]
    # curl http://10.10.1.61:4567/vnf-monitoring/5730bdfdb18cfb5a82000003/readings -H "Content-Type: application/json" -d '[{"instance": "cc58b58f-d38c-48b6-8e83-d238bea0568e", "measurements": [{"timestamp": "1970-01-01T00:00:00Z", "value": 197742, "units": "jiffies", "type": "cpuidle"}]}]'
    # @method post_vnf_monitoring_readings
    # @overload post '/vnf-monitoring/:vnfi_id/readings'
    # Receive the monitoring data
    post '/vnf-monitoring/:vnfr_id/readings' do |vnfr_id|
        logger.info 'Readings from Monitoring VIM'
        return 415 unless request.content_type == 'application/json'
        json, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        # get RabbitMQ channel information
        ch = settings.channel

        json.each do |instance|
            metrics = []
            instance['measurements'].each do |measurement|
                metric = {
                    instance_id: vnfr_id,
                    type: measurement['type'],
                    value: measurement['value'],
                    unit: measurement['units'],
                    timestamp: Time.parse(measurement['timestamp']).to_i
                }
                metrics.push(metric)

                q = ch.queue(params['vnfr_id'])
                q.publish(metric.to_json, persistent: true)

                q = ch.queue('vnf_repository')
                q.publish(metric.to_json, persistent: true)
            end

            return 200

            # to remove
            begin
                respone = RestClient.post settings.vnf_instance_repository + '/vnf-monitoring/' + vnfr_id, metrics.to_json, content_type: :json, accept: :json
            rescue => e
                puts e
                puts 'Error saving values to Cassandra.'
            end

            begin
                RestClient.post settings.ns_manager + '/ns-monitoring/vnf-instance-readings/' + vnfr_id, metrics.to_json, content_type: :json, accept: :json
            rescue => e
                puts e
                puts 'Error with sending the values to the NS Monitoring.'
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
            response = RestClient.get settings.vnf_instance_repository + request.fullpath, content_type: :json
        rescue => e
            logger.error e.response
            # return e.response.code, e.response.body
        end
        return response
    end

    # @method get_monitoring_data_100
    # @overload delete '/vnf-monitoring/:instance_id/monitoring-data/last100'
    #	Get monitoring data, last 100 values
    #	@param [Integer] instance_id
    get '/vnf-monitoring/:instance_id/monitoring-data/last100/' do
        begin
            response = RestClient.get settings.vnf_instance_repository + request.fullpath, content_type: :json
        rescue => e
            logger.error e.response
            # return e.response.code, e.response.body
        end
        return response
    end
end
