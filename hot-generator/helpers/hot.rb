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

	# Checks if a JSON message is valid
	#
	# @param [JSON] message the JSON message
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

		return parsed_message
	end

	# Generate a HOT template
	#
	# @param [JSON] vnfd the vnfd
	# @param [String] flavour_key the T-NOVA flavour
	# @param [Array] networks_id the IDs of the networks created by the NS Manager
	# @param [String] security_group_id the ID of the T-NOVA security group
	# @return [Hash] the generated hot template
	def generate_hot_template(vnfd, flavour_key, networks_id, security_group_id)
		hot = VnfdToHot.new(vnfd['name'], vnfd['description'])

		begin
			hot.build(vnfd, flavour_key, networks_id, security_group_id)
		rescue CustomException::NoExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidTemplateFileFormat => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::NoFlavorError => e
			logger.error e.message
			halt 400, e.message
		end
	end
end