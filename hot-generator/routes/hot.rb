#
# TeNOR - HOT Generator
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
# @see OrchestratorHotGenerator
class OrchestratorHotGenerator < Sinatra::Application

	# @method post_hot_flavour
	# @overload post '/hot/:flavour'
	# 	Convert a VNFD into a HOT
	# 	@param [String] flavour the T-NOVA flavour to generate the HOT
	# 	@param [JSON] the VNFD to convert
	# Convert a VNFD into a HOT
	post '/hot/:flavour' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		provision_info = parse_json(request.body.read)
		vnf = provision_info['vnf']

		networks_id = provision_info['networks_id']
		halt 400, 'Networks ID not found' if networks_id.nil?

		security_group_id = provision_info['security_group_id']
		halt 400, 'Security group ID not found' if security_group_id.nil?
		
		puts 'VNF: ' + vnf.to_json
		logger.debug 'Networks IDs: ' + networks_id.to_json
		logger.debug 'Security Group ID: ' + security_group_id.to_json

		# Build a HOT template
		logger.debug 'T-NOVA flavour: ' + params[:flavour]
		hot = generate_hot_template(vnf['vnfd'], params[:flavour], networks_id, security_group_id)
		puts 'HOT: ' + hot.to_json

		halt 200, hot.to_json
	end

	# @method post_networkhot_flavour
	# @overload post '/networkhot/:flavour'
	# 	Build a HOT to create the networks
	# 	@param [String] flavour the T-NOVA flavour to generate the HOT
	# 	@param [JSON] the networks information
	# Convert a VNFD into a HOT
	post '/networkhot/:flavour' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		networkInfo = parse_json(request.body.read)

		nsd = networkInfo['nsd']
		halt 400, 'NSD not found' if nsd.nil?

		public_net_id = networkInfo['public_net_id']
		halt 400, 'Public network ID not found' if public_net_id.nil?

		dns_server = networkInfo['dns_server']
		halt 400, 'DNS server not found' if dns_server.nil?

		# Build a HOT template
		logger.debug 'T-NOVA flavour: ' + params[:flavour]
		hot = generate_network_hot_template(nsd, public_net_id, dns_server, params[:flavour])
		puts 'Network HOT: ' + hot.to_json

		halt 200, hot.to_json
	end

	# @method post_wicmhot
	# @overload post '/wicmhot'
	# 	Build a HOT to create the WICM-SFC integration
	# Convert a VNFD into a HOT
	post '/wicmhot' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		provider_info = parse_json(request.body.read)

		# Build a HOT template
		hot = generate_wicm_hot_template(provider_info)
		puts 'WICM HOT: ' + hot.to_json

		halt 200, hot.to_json
	end

end