#
# TeNOR - VNF Catalogue
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
# @see OrchestratorVnfCatalogue
class OrchestratorVnfCatalogue < Sinatra::Application

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

	# Builds pagination link header
	#
	# @param [Integer] offset the pagination offset requested
	# @param [Integer] limit the pagination limit requested
	# @return [String] the built link to use in header
	def build_http_link(offset, limit)
		link = ''
		# Next link
		next_offset = offset + 1
		next_vnfs = Vnf.paginate(:page => next_offset, :limit => limit)
		link << '<localhost:4569/vnfs?offset=' + next_offset.to_s + '&limit=' + limit.to_s + '>; rel="next"' unless next_vnfs.empty?

		unless offset == 1
			# Previous link
			previous_offset = offset - 1
			previous_vnfs = Vnf.paginate(:page => previous_offset, :limit => limit)
			unless previous_vnfs.empty?
				link << ', ' unless next_vnfs.empty?
				link << '<localhost:4569/vnfs?offset=' + previous_offset.to_s + '&limit=' + limit.to_s + '>; rel="last"'
			end
		end
		link
	end

	# Method which lists all available interfaces
	#
	# @return [Array] an array of hashes containing all interfaces
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
			}
		]
	end
	
end