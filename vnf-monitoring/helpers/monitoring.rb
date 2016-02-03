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

	# Checks if a JSON message is valid
	#
	# @param [JSON] message some JSON message
	# @return [Hash, nil] if the parsed message is a valid JSON
	# @return [Hash, String] if the parsed message is an invalid JSON
	def parse_json(message)
		# Check JSON message format
		begin
			parsed_message = JSON.parse(message) # parse json message
		rescue JSON::ParserError => e
			# If JSON not valid, return with errors
			logger.error "JSON parsing: #{e.to_s}"
			return message, e.to_s + "\n"
		end

		return parsed_message, nil
	end


	def create_monitoring_metric_object(json)
		obj = MonitoringMetric.new(nsi_id: json['nsi_id'])
		vnf_instances = json['vnf_instances']

		vnf_instances.each do |vnf_instance|
			parameters = vnf_instance['parameters']
			params = []
			parameters.each do |parameter|
				params.push(Parameter.new(name: parameter['name'], unit: parameter['unit'], formula: parameter['formula']))
			end
			obj.vnf_instances.push(VnfInstance.new(vnf_id: vnf_instance['id'], parameters: params))
			obj.parameters.push(params)
		end
				logger.error obj.to_json
		#	vnf_instances.each do |vnf_instance|
		#			obj.vnf_instances.push(ConstituentVdu.new(vdu_reference: constituent_vdu['vdu_reference'], number_of_instances: constituent_vdu['number_of_instances'], constituent_vnfc: constituent_vdu['constituent_vnfc']))
		#		end

		return obj
	end

	def generateMetric(key, value)
		json = {metric: key, value: value}
		return json
	end
end