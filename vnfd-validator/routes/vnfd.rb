#
# TeNOR - VNFD Validator
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
# @see OrchestratorVnfdValidator
class OrchestratorVnfdValidator < Sinatra::Application

	before do
    	if request.path_info == '/gk_credentials'
      		return
    	end

    	if settings.environment == 'development'
      		return
    	end

    	authorized?
  end

	# @method get_root
	# @overload get '/'
	#       Get all available interfaces
	# Get all interfaces
    get '/' do
    	halt 200, interfaces_list.to_json
    end
	
	# @method post_vnfds
	# @note You have to specify the correct Content-Type
	# @overload post '/vnfds'
	# 	Post a VNFD in JSON format
	# 	@param [JSON]
	# 	@example Header for JSON
	# 		Content-Type: application/json
	# @overload post '/vnfds'
	# 	Post a VNFD in XML format
	# 	@deprecated XML support is deprecated. Use JSON instead.
	# 	@param [XML]
	# 	@example Header for XML
	# 		Content-Type: application/xml
	#
	# Post a VNFD
	post '/vnfds' do
		# Read body content-type
		content_type = request.content_type
		body = request.body.read
		logger.debug "Content-Type: #{content_type}"

		# Return if content-type is invalid
		halt 415 unless ( (content_type == 'application/json') or (content_type == 'application/xml') )

		# If message in JSON format
		if content_type == 'application/json'
			# Parse body as a JSON
			vnfd = parse_json(body)
			logger.debug 'Parsed JSON VNFD'

			# Validate VNFD
			vnfd = validate_json_vnfd(vnfd)
			logger.debug 'Validated VNFD with JSON schema'
		end

		# Parse XML format
		if content_type == 'application/xml'
			# Parse body as a XML
			vnfd = parse_xml(request.body.read)

			# Validate VNFD
			vnfd = validate_xml_vnfd(vnfd)
		end

		logger.debug 'Verifying VDU images'
		verify_vdu_images(vnfd['vdu'])

		halt 200
	end
end