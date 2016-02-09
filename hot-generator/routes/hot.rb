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

	before do
    	if request.path_info == '/gk_credentials'
      		return
    	end

    	if settings.environment == 'development'
      		return
    	end

    	authorized?
  end
	
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
		
		logger.debug 'VNF: ' + vnf.to_json
		logger.debug 'Networks IDs: ' + networks_id.to_json
		logger.debug 'Security Group ID: ' + security_group_id.to_json

		# Build a HOT template
		logger.debug 'T-NOVA flavour: ' + params[:flavour]
		hot = generate_hot_template(vnf['vnfd'], params[:flavour], networks_id, security_group_id)
		logger.debug 'HOT: ' + hot.to_json

		halt 200, hot.to_json
	end

end