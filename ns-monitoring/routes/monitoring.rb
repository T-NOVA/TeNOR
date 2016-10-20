#
# TeNOR - NS Monitoring
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
# @see NSMonitoring
class NSMonitoring < Sinatra::Application
    # definition metric should be monitoring, received from NSProvisioning
    # 		{
    # 	 "nsi_id": "1",
    # 	 "vnf_instances": [
    # 	   { "id": "1", "parameters": [
    # 	     { "id": "1", "name": "availability", "unit": "percentage", "value": "string"},
    # 	     { "id": "2", "name": "num_sessions", "unit": "integer", "value": "string"} ]
    # 	   },
    # 	   { "id": "2", "parameters": [
    # 	     { "id": "1", "name": "availability", "unit": "percentage", "value": "string"},
    # 	     { "id": "2", "name": "num_sessions", "unit": "integer", "value": "string"} ]
    # 	   }
    # 	 ],
    # 	 "parameters": [
    # 	   { "id": "1", "name": "availability", "formula": "min(vnf_instance[1].availability, vnf_instance[2].availability)"},
    # 	   { "id": "2", "name": "num_sessions", "formula": "vnf_instances[1].num_sessions+vnf_instances[2].num_sessions"}
    # 	 ]
    # 	}

    # @method post_monitoring_parameters
    # @overload post '/network-services/:external_vnf_id'
    #	Post monitoring parameters
    #	@param [Integer] external_ns_id NS external ID
    post '/ns-monitoring/monitoring-parameters' do
        return 415 unless request.content_type == 'application/json'

        # Validate JSON format
        monitoring, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        logger.debug monitoring

        # logger.error threads
        logger.error @@testThreads
        nsi_id = monitoring['nsi_id'].to_s

        # Create SLA object
        sla = Sla.new(nsi_id: nsi_id)
        return 422, "Could not create SLA from #{monitoring}.\n" unless sla

        monitoring['parameters'].each do |parameter|
            sla.parameters << Parameter.new(parameter_id: parameter['id'], name: parameter['name'], threshold: parameter['value'])
        end
        sla.save!

        NsMonitoringParameter.new(monitoring).save!

        logger.info 'Sending subscription monitoring to VNF Manager.'
        monitoring['vnf_instances'].each do |vnf_instance|
            logger.debug 'VNFD: ' + vnf_instance['id'] # vnf_id
            logger.debug 'VNFr: ' + vnf_instance['vnfr_id']
            object = {}
            #       object = {
            #           :parameter_id => parameter['id'],
            #           :name => parameter['name']
            #           #:vnfr_id => @ns_instance['vnfrs'][0]['vnfr_id']
            #           #,:unit => parameter['unit']
            #       }
            #       logger.debug object
            begin
                response = RestClient.post settings.vnf_manager + '/vnf-monitoring/' + vnf_instance['vnfr_id'] + '/monitoring-parameters', object.to_json, content_type: :json, accept: :json
            rescue => e
                logger.error 'ERROR'
                logger.error e
                halt 400, 'VNF Manager not available'
            end
        end

        Thread.new do
            Thread.current['name'] = nsi_id
            MonitoringHelper.subcriptionThread(monitoring)
            Thread.stop
        end

        return 200, 'Subscription correct.'
    end

    # @method post_monitoring_data_unsubcribe
    # @overload post '/monitoring-data/unsubscribe:nsi_id'
    #	Unsubcribe ns instance
    #	@param [Integer] external_ns_id NS external ID
    post '/monitoring-data/unsubscribe/:nsi_id' do |nsi_id|
        logger.info "Unsubcribe " + nsi_id
        begin
            monMetrics = NsMonitoringParameter.find_by('nsi_id' => nsi_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 400, 'Monitoring Metric instance no exists'
        end

        # for each vnf_instance, cancel the subscription and remove the threads
        monMetrics['vnf_instances'].each do |monitoring_vnf|
            logger.debug monitoring_vnf
            logger.debug monitoring_vnf['id']
            logger.info 'Removing threads...'
            @@testThreads.delete_if do |thr|
                puts thr[:vnfi_id]
                puts monitoring_vnf['vnfr_id']
                if thr[:vnfi_id] == monitoring_vnf['vnfr_id']
                    thr[:queue].cancel
                    true
                end
            end
        end

        begin
            sla = Sla.find_by('nsi_id' => nsi_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 400, 'Sla no exists'
        end

        destroy_monitoring_data(nsi_id)

        monMetrics.destroy
        sla.destroy

        halt 200, "Correct unsubcription."
    end

    # This interface is with the VNF Monitoring micro-service, upon successfully receiving a monitoring parameter reading for a given VNF instance.
    #	{
    #  "parameter_id": "1",
    #  "value": "99.99",
    #  "timestamp": "2015-06-18T09:42:10Z"
    # }
    # @method post_ns_monitoring_vnf_instance_readings
    # @overload post '/  # @method post_ns_monitoring_vnf_instance-readings'
    #	Receive the monitoring data from the VNF manager
    #	@param [Integer] vnfr_id VNFR id
    post '/ns-monitoring/vnf-instance-readings/:vnfr_id' do |vnfr_id|
        return 415 unless request.content_type == 'application/json'

        # Validate JSON format
        measurements, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        logger.debug measurements

        begin
            monMetrics = NsMonitoringParameter.find_by('vnf_instances.vnfr_id' => vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            # halt 400, "Monitoring Metric instance no exists"
        end

        logger.debug monMetrics

        conn = Bunny.new
        conn.start

        ch = conn.create_channel
        q = ch.queue(vnfr_id)
        logger.error 'Publishing the values...'
        q.publish(measurements.to_json, persistent: true)
        conn.close

        return
    end

    # @method get_monitoring_data
    # @overload get '/ns-monitoring/:instance_id/monitoring-data'
    #	Get monitoring data
    #	@param [Integer] instance_id
    get '/ns-monitoring/:instance_id/monitoring-data/' do
        begin
            response = RestClient.get settings.ns_monitoring_repo + request.fullpath, content_type: :json
        rescue => e
            logger.error e.response
            # return e.response.code, e.response.body
        end
        return response
    end

    # @method get_monitoring_data_100
    # @overload delete '/ns-monitoring/:instance_id/monitoring-data/last100'
    #	Get monitoring data, last 100 values
    #	@param [Integer] instance_id
    get '/ns-monitoring/:instance_id/monitoring-data/last100/' do
        begin
            response = RestClient.get settings.ns_monitoring_repo + request.fullpath, content_type: :json
        rescue => e
            logger.error e.response
            # return e.response.code, e.response.body
        end
        return response
    end
end
