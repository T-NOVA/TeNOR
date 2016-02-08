#
# TeNOR - NSD Validator
#
# Copyright 2014-2016 i2CAT Foundation
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
# @see OrchestratorNsdValidator
class OrchestratorNsdValidator < Sinatra::Application

	before do

		if request.path_info == '/gk_credentials'
			return
		end

		if settings.environment == 'development'
			return
		end

		authorized?
	end

	# @method post_nsds
	# @note You have to specify the correct Content-Type
	# @overload post '/nsds'
	# 	Post a NSD in JSON format
	# 	@param [JSON]
	# 	@example Header for JSON
	# 		Content-Type: application/json
	# @overload post '/nsds'
	# 	Post a NSD in XML format
	# 	@param [XML]
	# 	@example Header for XML
	# 		Content-Type: application/xml
	#
	# Post a NSD
	post '/nsds' do
		# Read body content-type
		content_type = request.content_type
		body = request.body.read

		# Return if content-type is invalid
		return 415 unless ( (content_type == 'application/json') or (content_type == 'application/xml') )

		# If message in JSON format
		if content_type == 'application/json'
			# Check if message is a valid JSON
			nsd, errors = parse_json(body)
			return 400, errors if errors

			# Check if message is a valid NSD
			nsd, errors = validate_json_nsd(nsd)
			return 400, errors if errors
		end

		# Parse XML format
		if content_type == 'application/xml'
			# Check if message is a valid XML
			nsd, errors = parse_xml(request.body.read)
			return 400, errors.to_json if errors

			# Check if message is a valid NSD
			nsd, errors = validate_xml_nsd(nsd)
			return 400, errors if errors
		end

		return 200
	end

end
