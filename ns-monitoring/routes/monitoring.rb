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

  before do

    if request.path_info == '/gk_credentials'
      return
    end

    if settings.environment == 'development'
      return
    end

    authorized?
  end

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
  post '/ns-monitoring/monitoring-parameters' do
    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    monitoring, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.debug json

    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + monitoring['nsi_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    @ns_instance, errors = parse_json(response)
    return 400, errors.to_json if errors

    monitoring['vnf_instances'].each do |vnf_instance|
      puts vnf_instance['id'] #vnf_id
      puts vnf_instance['vnfr_id']
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
        logger.error object

        #send to VNF-Monitoring the metrics to monitor
        begin
          response = RestClient.post settings.vnf_manager + '/vnf-monitoring/' + vnf_instance['vnfr_id'] + '/monitoring-parameters', object.to_json, :content_type => :json, :accept => :json
        rescue
          puts "ERROR"
          halt 400, "VNF Manager not available"
        end

        subscription_response, errors = parse_json(response)
        return 400, errors.to_json if errors

        logger.error subscription_response

      end
    end

    return 200, "Subscription correct."

  end

  #This interface is with the VNF Monitoring micro-service, upon successfully receiving a monitoring parameter reading for a given VNF instance.
  #	{
  #  "parameter_id": "1",
  #  "value": "99.99",
  #  "timestamp": "2015-06-18T09:42:10Z"
  #}
  post '/ns-monitoring/vnf-instance-readings/:vnfr_id' do
    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    measurement, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.error measurement

    begin
      monMetrics = NsMonitoringParameter.find_by("vnf_instances.vnfr_id" => params['vnfr_id'])
      logger.error monMetrics
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 400, "Monitoring Metric instance no exists"
    end

    logger.error monMetrics

    parameter_name = monMetrics['parameters'].find {|p| p['id'] == measurement['parameter_id']}['name']
    puts "Parameter name:"
    puts parameter_name

    #logger.error paramInfo

    if monMetrics.vnf_instances.length == 1
      #store value in cassandra
      metrics = {
          :type => parameter_name,
          :value => measurement['value'],
          :unit => measurement['unit'],
          :timestamp => measurement['timestamp']
      }
      begin
        RestClient.post settings.ns_monitor_db + '/ns-monitoring/' + monMetrics['nsi_id'], metrics.to_json, :content_type => :json, :accept => :json
      rescue => e
        logger.error e.response
        return e.response.code, e.response.body
      end
      return
    end

    puts "TODO"
    return
    parametersSize = 0

    #enrich data, wait response from each vnf-parameter and vnfs
    monMetrics.vnf_instances.each do |vnfInstance|
      next if (vnfInstance['id'] != params['vnf_instance_id'])
      parametersSize = vnfInstance['parameters'].length
      vnfInstance['parameters'].each do |parameters|
        #next if (vnfInstance['id'] != response['parameter_id'])
        logger.error "parameter............................"

        @queue = VnfQueue.where(:vnfi_id => vnfInstance['id'])
        if @queue.length == 0
          VnfQueue.new({
                           :vnfi_id => params['vnf_instance_id'],
                           :parameter_id => response['parameter_id'],
                           :value => response['value'],
                           :timestamp => response['timestamp']
                       }).save!
          #return
        end

        @queue.each do |queueValue|
          logger.error queueValue
          #next if (queueValue['parameter_id'] != response['parameter_id'])
          if response['parameter_id'] == queueValue['parameter_id']
            queueValue.update_attribute(:value, response['value'].to_s)
            break
          elsif response['parameter_id'] == parameters['id']
            logger.error "Saving value2 ................................"
            #if response['parameter_id'] == queueValue['parameter_id']
            VnfQueue.new({
                             :vnfi_id => params['vnf_instance_id'],
                             :parameter_id => response['parameter_id'],
                             :value => response['value'],
                             :timestamp => response['timestamp']
                         }).save!
            #return
          end
        end


      end
    end

    logger.error "-----------------------------------" + @queue.length.to_s + "................................."
    if @queue.length >= parametersSize
      logger.error "Send to expression module"
      @queue.delete
    end

    return
  end

  #This interface is with the SLA Enforcement micro-service, upon successfully registering .
  post '/ns-monitoring' do
    #TODO

  end

  #/ns-monitoring/instances/10/monitoring-data/
  get '/ns-monitoring/instances/:instance_id/monitoring-data/' do
    composedUrl = '/ns-monitoring/' + params["instance_id"].to_s + "/monitoring-data/?" + request.env['QUERY_STRING']
    begin
      response = RestClient.get settings.ns_monitor_db + composedUrl, :content_type => :json
    rescue => e
      logger.error e.response
      #return e.response.code, e.response.body
    end
    return response
  end

end