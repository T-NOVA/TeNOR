#
# TeNOR - VNF Manager
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
# @see OrchestratorVnfManager
class OrchestratorVnfManager < Sinatra::Application

	# Checks if a JSON message is valid
	#
	# @param [JSON] message some JSON message
	# @return [Hash] if the parsed message is a valid JSON
	def parse_json(message)
		# Check JSON message format
		begin
			parsed_message = JSON.parse(message) # parse json message
		rescue JSON::ParserError => e
			# If JSON not valid, return with errors
			logger.error "JSON parsing: #{e.to_s}"
			halt 400, e.to_s + "\n"
		end

		parsed_message
	end

	# Method which lists all available interfaces
	#
	# @return [Array] the array containing a list of all interfaces
	def interfaces_list
		[
			{
				'uri' => '/',
				'method' => 'GET',
				'purpose' => 'REST API Structure and Capability Discovery'
			},
			{
				'uri' => '/vnfs',
				'method' => 'GET',
				'purpose' => 'List all VNFs'
			},
			{
				'uri' => '/vnfs/{external_vnf_id}',
				'method' => 'GET',
				'purpose' => 'List a specific VNF'
			},
			{
				'uri' => '/vnfs',
				'method' => 'POST',
				'purpose' => 'Store a new VNF'
			},
			{
				'uri' => '/vnfs/{external_vnf_id}',
				'method' => 'PUT',
				'purpose' => 'Update a stored VNF'
			},
			{
				'uri' => '/vnfs/{external_vnf_id}',
				'method' => 'DELETE',
				'purpose' => 'Delete a specific VNF'
			},
        	{
        		'uri' => '/vnf-instances',
        		'method' => 'POST',
        		'purpose' => 'Request the instantiation of a VNF'
        	},
        	{
        		'uri' => '/configs',
        		'method' => 'GET',
        		'purpose' => 'List all services configurations'
        	},
        	{
        		'uri' => '/configs/{config_id}',
        		'method' => 'GET',
        		'purpose' => 'List a specific service configuration'
        	},
        	{
        		'uri' => '/configs/{config_id}',
        		'method' => 'PUT',
        		'purpose' => 'Update a service configuration'
        	},
        	{
        		'uri' => '/configs/{config_id}',
        		'method' => 'DELETE',
        		'purpose' => 'Delete a service configuration'
        	}
		]
	end
end