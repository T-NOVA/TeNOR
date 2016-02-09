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
		json, errors = parse_json(request.body.read)
		return 400, errors.to_json if errors

		logger.debug json

		begin
			response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + json['nsi_id'].to_s, :content_type => :json
		rescue => e
			logger.error e
			if (defined?(e.response)).nil?
				halt 503, "NS-Instance Repository unavailable"
			end
			halt e.response.code, e.response.body
		end
		@ns_instance, errors = parse_json(response)
		return 400, errors.to_json if errors

		#read instance info from nsi_id
		logger.debug @ns_instance
    @ns_instance['vnfs'].each  do |vnf|
      logger.debug vnf
      logger.debug vnf['vnfi_id'][0]
    end

		#read the vnfi_id from there
		@monitoring_metrics = create_monitoring_metric_object(json)
		@monitoring_metrics.save!

		@monitoring_metrics.parameters.each do |parameter|
			logger.debug parameter
			object = {
					:parameter_id => parameter['id'],
					:name => parameter['name']
					#,:unit => parameter['unit']
			}
			logger.error object

			#send to VNF-Monitoring the metrics to monitor
			begin
				RestClient.post settings.vnf_manager + '/vnf-monitoring/'+@ns_instance['vnfs'][0]['vnfi_id'][0]+'/monitoring-parameters', object.to_json, :content_type => :json, :accept => :json
			rescue
				halt 400, "VNF Manager not available"
			end
    end

    return 200

		#	{
		#	 "parameter_id": "uuid",
		#  "name": "avaliability",
		#  "unit": "percentage"
		#}

		#	{
		#"parameters": [
		#{ "id": "1", "name": "availability", "unit": "percentage"},
		#{ "id": "2", "name": "num_sessions", "unit": "integer"}
		#]
		#}
		#[{"parameters":[{"id":41,"name":"availability","unit":"%"},{"id":42,"name":"ram-consumption","unit":"MB"}]}]

  end


  #This interface is with the VNF Monitoring micro-service, upon successfully receiving a monitoring parameter reading for a given VNF instance.
	#	{
	#  "parameter_id": "1",
	#  "value": "99.99",
	#  "timestamp": "2015-06-18T09:42:10Z"
	#}
	post '/ns-monitoring/vnf-instance-readings/:vnf_instance_id' do
		return 415 unless request.content_type == 'application/json'

		# Validate JSON format
		response, errors = parse_json(request.body.read)
		return 400, errors.to_json if errors

    logger.error response

    #NsMonitoringParameter.find_by()

		#@vnf_monitoring_data = VNFMonitoringData.new json
		#logger.error @vnf_monitoring_data.to_json

		#given the vnf_instance_id, search in which ns_id belongs to
		begin
			vnfInstance = VnfInstance.find_by(:vnf_id => params['vnf_instance_id'])
		rescue Mongoid::Errors::DocumentNotFound => e
			#halt 400, "VNF instance no exists"
		end

    logger.debug vnfInstance
		begin
			#monMetrics = NsMonitoringParameter.find_by(:nsi_id => vnfInstance['ns_monitoring_parameter_id'].to_s)
			monMetrics = NsMonitoringParameter.find_by("vnf_instances.id" => params['vnf_instance_id'])
			logger.error monMetrics
		rescue Mongoid::Errors::DocumentNotFound => e
			halt 400, "Monitoring Metric instance no exists"
		end

		begin
    	#parameter = Parameter.find_by(:id => response['parameter_id'])
		rescue Mongoid::Errors::DocumentNotFound => e
			#halt 400, "VNF instance no exists"
		end

		#logger.error parameter['name']
    logger.error monMetrics

		#given the parameter_id of this request, search the paramter info of that vnf_id

		#paramInfo = Parameter.find_by(:ns_monitoring_parameter_id => monMetrics['id'], :id => response['parameter_id'] )

    #logger.error paramInfo

		if monMetrics.vnf_instances.length == 1
			#store value in cassandra
			data = generateMetric(paramInfo['name'], response['value'])
			begin
				RestClient.post settings.ns_monitor_db + '/ns-monitoring/:vnf_instance_id', data.to_json, :content_type => :json, :accept => :json
			rescue => e
				logger.error e.response
				return e.response.code, e.response.body
			end
			return
    end

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