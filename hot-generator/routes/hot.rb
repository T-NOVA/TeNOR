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
class HotGenerator < Sinatra::Application

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
		provision_info = JSON.parse(request.body.read)
		#return 400, errors.to_json if errors

		vnf = provision_info['vnf']

		networks_id = provision_info['networks_id']
		halt 400, 'Networks ID not found' if networks_id.nil?

		routers_id = provision_info['routers_id']
		halt 400, 'Routers ID not found' if routers_id.nil?

		if provision_info['security_group_id'].nil?
			security_group_id = nil
		end

		vnfr_id = provision_info['vnfr_id']
		halt 400, 'Vnfr ID not found' if vnfr_id.nil?

		logger.debug 'Networks IDs: ' + networks_id.to_json
		logger.debug 'Security Group ID: ' + security_group_id.to_json

		dns_server = provision_info['dns_server']
		halt 400, 'DNS server not found' if dns_server.nil?

    public_network_id = provision_info['public_network_id']
    halt 400, 'Public Network ID not found' if public_network_id.nil?

		# Build a HOT template
		logger.debug 'T-NOVA flavour: ' + params[:flavour]
		hot = CommonMethods.generate_hot_template(vnf['vnfd'], params[:flavour], networks_id, routers_id, security_group_id, vnfr_id, dns_server, public_network_id)

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
		networkInfo = JSON.parse(request.body.read)
    #return 400, errors.to_json if errors

		nsr_id = networkInfo['nsr_id']
		halt 400, 'NSR ID not found' if nsr_id.nil?

		nsd = networkInfo['nsd']
		halt 400, 'NSD not found' if nsd.nil?

		public_net_id = networkInfo['public_net_id']
		halt 400, 'Public network ID not found' if public_net_id.nil?

		dns_server = networkInfo['dns_server']
		halt 400, 'DNS server not found' if dns_server.nil?

		# Build a HOT template
		logger.debug 'T-NOVA flavour: ' + params[:flavour]
		hot = CommonMethods.generate_network_hot_template(nsd, public_net_id, dns_server, params[:flavour], nsr_id)

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
		provider_info = JSON.parse(request.body.read)
    #return 400, errors.to_json if errors

		# Build a HOT template
		hot = CommonMethods.generate_wicm_hot_template(provider_info)

		halt 200, hot.to_json
	end

	# @method post_networkhot_flavour
	# @overload post '/networkhot/:flavour'
	# 	Build a HOT to create the networks
	# 	@param [String] flavour the T-NOVA flavour to generate the HOT
	# 	@param [JSON] the networks information
	# Convert a VNFD into a HOT
	post '/scale/:flavour' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    provision_info = JSON.parse(request.body.read)
    #return 400, errors.to_json if errors

    vnf = provision_info['vnf']

    networks_id = provision_info['networks_id']
    halt 400, 'Networks ID not found' if networks_id.nil?

    security_group_id = provision_info['security_group_id']
    halt 400, 'Security group ID not found' if security_group_id.nil?

    logger.debug 'Networks IDs: ' + networks_id.to_json
    logger.debug 'Security Group ID: ' + security_group_id.to_json

    # Build a HOT template
		logger.debug 'Scale T-NOVA flavour: ' + params[:flavour]
		hot = CommonMethods.generate_hot_template_scaling(vnf['vnfd'], params[:flavour], networks_id, security_group_id)

		halt 200, hot.to_json
	end

	# @method post_netflochot
	# @overload post '/netfloc'
	# 	Build a HOT to create the Netfloc integration
	# Convert a VNFFG into a HOT
	post '/netfloc' do
		# Return if content-type is invalid
		halt 415 unless request.content_type == 'application/json'

		# Validate JSON format
		provision_info = JSON.parse(request.body.read)
		#return 400, errors.to_json if errors

		ports = provision_info['ports']
		halt 400, 'Ports not found' if ports.nil?

		odl_username = provision_info['odl_username']
		halt 400, 'ODL username not found' if odl_username.nil?

		odl_password = provision_info['odl_password']
		halt 400, 'ODL password not found' if odl_password.nil?

		netfloc_ip_port = provision_info['netfloc_ip_port']
		halt 400, 'Netfloc IP not found' if netfloc_ip_port.nil?

		# Build a HOT template
		hot = CommonMethods.generate_netfloc_hot_template(ports, odl_username, odl_password, netfloc_ip_port)

		halt 200, hot.to_json
	end

	get '/files/:file_name' do
    File.read(File.join('assets/templates', params[:file_name]))
	end

end
