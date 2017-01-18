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

        json, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        json['vnfr_id'] = vnfr_id
        vnfd = json['vnfd']

        json['vnfd']['vnfd']['vdu'].each do |vdu|
            monitoring_info = {}
            types = []
            vdu_id = json['vnfr']['vms_id'][vdu['id']]
            #json['vnfr']['vms_id'].find { |_key, value| instances << value }
            vdu['monitoring_parameters'].each do |mP|
                types.push(mP['metric']) unless types.include?(mP['metric'])
            end
            vdu['monitoring_parameters_specific'].to_a.each do |mP|
                types.push(mP['metric']) unless types.include?(mP['metric'])
            end

            logger.info "Creating subscription message for VDU: #{vdu['id']}"
            callbackUrl = settings.manager + "/vnf-monitoring/#{vnfr_id}/readings"
            url = 'http://' + callbackUrl unless callbackUrl.include? 'http://'
            subscribe = {
                types: types,
                instances: [vdu_id],
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

            logger.debug "Subscription id: " + response.split("under ID ")[1].to_s
            monitoring_info = {
                vnfr_id: vnfr_id,
                vdu_id: vdu['id'],
                vdu_uid: vdu_id,
                subscription_id: response.split("under ID ")[1].to_s
            }
            MonitoringMetric.new(monitoring_info).save!
        end

        return 200
    end

    delete '/vnf-monitoring/subscription/:vnfr_id' do |vnfr_id|
        begin
            monitoring_metrics = MonitoringMetric.where(:vnfr_id => vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error "Monitoring Metric no exists."
            halt 400, 'Sla no exists'
        end
        logger.debug "Remove subcription #{monitoring_metrics.to_json}"
        monitoring_metrics.each do |mon_metrics|
            begin
                response = RestClient.delete settings.vim_monitoring + '/api/subscriptions/' + mon_metrics['subscription_id'], accept: :json
            rescue => e
                puts e
                halt 400, 'VIM Monitoring Module not available'
            end
            mon_metrics.destroy
        end
        destroy_monitoring_data(vnfr_id)
        halt 200
    end

    # @method post_vnf_monitoring_readings
    # @overload post '/vnf-monitoring/:vnfi_id/readings'
    # Receive the monitoring data
    post '/vnf-monitoring/:vnfr_id/readings' do |vnfr_id|
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
                    vdu_id: instance['instance'],
                    type: measurement['type'],
                    value: measurement['value'],
                    unit: measurement['units'],
                    timestamp: Time.parse(measurement['timestamp']).to_i
                }
                metrics.push(metric)

                #only push to Manager the assurance metrics?
                q = ch.queue(params['vnfr_id'])
                q.publish(metric.to_json, persistent: true)

            end
            q = ch.queue('vnf_repository')
            q.publish(metrics.to_json, persistent: true)
=begin
            begin
                respone = RestClient.post settings.manager + '/vnf-monitoring/' + vnfr_id, metrics.to_json, content_type: :json, accept: :json
            rescue => e
                puts e
                puts 'Error saving values to Cassandra.'
            end

            begin
                RestClient.post settings.manager + '/ns-monitoring/vnf-instance-readings/' + vnfr_id, metrics.to_json, content_type: :json, accept: :json
            rescue => e
                puts e
                puts 'Error with sending the values to the NS Monitoring.'
            end
=end
        end
        return 200
    end

    # @method get_monitoring_data
    # @overload get '/vnf-monitoring/:instance_id/monitoring-data/last'
    #	Get monitoring data, last 100 values
    #	@param [Integer] instance_id
    get '/vnf-monitoring/:instance_id/monitoring-data/' do
        begin
            response = RestClient.get settings.vnf_monitoring_repo + request.fullpath, content_type: :json
        rescue => e
            logger.error e
            # return e.response.code, e.response.body
        end
        return response
    end

    # @method get_monitoring_data_100
    # @overload get '/vnf-monitoring/:instance_id/monitoring-data/last100'
    #	Get monitoring data, last 100 values
    #	@param [Integer] instance_id
    get '/vnf-monitoring/:instance_id/monitoring-data/last100/' do
        begin
            response = RestClient.get settings.vnf_monitoring_repo + request.fullpath, content_type: :json
        rescue => e
            logger.error e
            # return e.response.code, e.response.body
        end
        return response
    end
end
