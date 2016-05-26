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

  #definition metric should be monitoring, received from NSProvisioning
=begin
		{
	 "nsi_id": "1",
	 "vnf_instances": [
	   { "id": "1", "parameters": [
	     { "id": "1", "name": "availability", "unit": "percentage"},
	     { "id": "2", "name": "num_sessions", "unit": "integer"} ]
	   },
	   { "id": "2", "parameters": [
	     { "id": "1", "name": "availability", "unit": "percentage"},
	     { "id": "2", "name": "num_sessions", "unit": "integer"} ]
	   }
	 ],
	 "parameters": [
	   { "id": "1", "name": "availability", "formula": "min(vnf_instance[1].availability, vnf_instance[2].availability)"},
	   { "id": "2", "name": "num_sessions", "formula": "vnf_instances[1].num_sessions+vnf_instances[2].num_sessions"}
	 ]
	}
=end

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

    #logger.error threads
    logger.error @@testThreads
    nsi_id = monitoring['nsi_id'].to_s
    #@@testThreads <<
    Thread.new {
      Thread.current["name"] = nsi_id
#      Thread.current[:name] = "NAmeasdada"
      Thread.current["name"] = nsi_id;
      MonitoringHelper.subcriptionThread(monitoring)
      Thread.stop
    }
    #@@testThreads <<  {:id => "", :thread => Thread.new {
    #  subcriptionThread(monitoring)
    #}
    #}

=begin
    begin
      response = RestClient.get settings.ns_provisioner + '/ns-instances/' + monitoring['nsi_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    @ns_instance, errors = parse_json(response)
    return 400, errors.to_json if errors
=end

    logger.error "Sending monitoring subcribe to VNF Manager."
    monitoring['vnf_instances'].each do |vnf_instance|
      logger.debug "VNFD: " + vnf_instance['id'] #vnf_id
      logger.debug "VNFr: " + vnf_instance['vnfr_id']
      object = {}
      begin
        response = RestClient.post settings.vnf_manager + '/vnf-monitoring/' + vnf_instance['vnfr_id'] + '/monitoring-parameters', object.to_json, :content_type => :json, :accept => :json
      rescue
        puts "ERROR"
        halt 400, "VNF Manager not available"
      end

    end

    monitoring['vnf_instances'].each do |vnf_instance|
      logger.debug "VNFD: " + vnf_instance['id'] #vnf_id
      logger.debug "VNFr: " + vnf_instance['vnfr_id']
      @monitoring_metrics = create_monitoring_metric_object(monitoring)
      @monitoring_metrics.save!

      @monitoring_metrics.parameters.each do |parameter|
        logger.debug parameter
        object = {
            :parameter_id => parameter['id'],
            :name => parameter['name']
            #:vnfr_id => @ns_instance['vnfrs'][0]['vnfr_id']
            #,:unit => parameter['unit']
        }
        logger.debug object

        #send to VNF-Monitoring the metrics to monitor
        begin
          response = RestClient.post settings.vnf_manager + '/vnf-monitoring/' + vnf_instance['vnfr_id'] + '/monitoring-parameters', object.to_json, :content_type => :json, :accept => :json
        rescue
          puts "ERROR"
          halt 400, "VNF Manager not available"
        end

        subscription_response, errors = parse_json(response)
        return 400, errors.to_json if errors

        logger.debug subscription_response

      end
    end

    return 200, "Subscription correct."
  end

  # @method post_monitoring_data_unsubcribe
  # @overload delete '/monitoring-data/unsubscribe:nsi_id'
  #	Unsubcribe ns instance
  #	@param [Integer] external_ns_id NS external ID
  post '/monitoring-data/unsubscribe/:nsi_id' do

    begin
      monMetrics = NsMonitoringParameter.find_by("nsi_id" => params['nsi_id'])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 400, "Monitoring Metric instance no exists"
    end

    #for each vnf_instance, cancel the subscription and remove the threads
    monMetrics['vnf_instances'].each do |monitoring_vnf|
      @@testThreads.delete_if do |thr|
        if thr[:vnfi_id] == monitoring_vnf['id']
          thr[:queue].cancel
          true
        end
      end
    end

  end

  # @method post_monitoring_parameters
  # @overload delete '/network-services/:external_vnf_id'
  #	Delete a NS by its ID
  #	@param [Integer] external_ns_id NS external ID
  get '/testa' do
    logger.error @@testThreads

    @@testThreads.delete_if do |thr|
      if thr[:vnfi_id] == '56d6c342b18cfb7afc000003' || thr[:vnfi_id] == '56d6c342b18cfb7afc000099'
        thr[:queue].cancel
        true
      end
    end

    Thread.list.each do |thread|
      logger.error thread.inspect
      if thread[:name] == '1'
        logger.error "Killing thread"
        puts thread[:name]
        #thread.exit
        Thread.kill thread
      end
    end
    return

  end

  #This interface is with the VNF Monitoring micro-service, upon successfully receiving a monitoring parameter reading for a given VNF instance.
  #	{
  #  "parameter_id": "1",
  #  "value": "99.99",
  #  "timestamp": "2015-06-18T09:42:10Z"
  #}

  # @method post_ns_monitoring_vnf_instance_readings
  # @overload post '/  # @method post_ns_monitoring_vnf_instance-readings'
  #	Receive the monitoring data from the VNF manager
  #	@param [Integer] vnfr_id VNFR id
  post '/ns-monitoring/vnf-instance-readings/:vnfr_id' do
    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    measurements, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.debug measurements

    begin
      monMetrics = NsMonitoringParameter.find_by("vnf_instances.vnfr_id" => params['vnfr_id'])
    rescue Mongoid::Errors::DocumentNotFound => e
      #halt 400, "Monitoring Metric instance no exists"
    end

    logger.debug monMetrics

    conn = Bunny.new
    conn.start

    ch = conn.create_channel
    q = ch.queue(params['vnfr_id'])
    logger.error "Publishing the values..."
    q.publish(measurements.to_json, :persistent => true)
    conn.close

    return
  end

  #This interface is with the SLA Enforcement micro-service, upon successfully registering .
  post '/ns-monitoring' do
    #TODO

  end

  # @method get_monitoring_data
  # @overload get '/ns-monitoring/:instance_id/monitoring-data'
  #	Get monitoring data
  #	@param [Integer] instance_id
  get '/ns-monitoring/:instance_id/monitoring-data/' do
    begin
      response = RestClient.get settings.ns_monitoring_repo + request.fullpath, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

  # @method get_monitoring_data_100
  # @overload delete '/ns-monitoring/:instance_id/monitoring-data/last100'
  #	Get monitoring data, last 100 values
  #	@param [Integer] instance_id
  get '/ns-monitoring/:instance_id/monitoring-data/last100/' do
    begin
      response = RestClient.get settings.ns_monitoring_repo + request.fullpath, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

end