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

	# Checks if a parsed JSON message is a valid NSD
	#
	# @param [Hash] nsd the JSON message parsed
	# @return [Hash, nil] if the JSON message is a valid NSD
	# @return [Hash, String] if the JSON message is an invalid NSD
	def validate_json_nsd(nsd)
		# Read NSD json schema
		json_schema = File.read(settings.json_schema)
		begin
			JSON::Validator.validate!(json_schema, nsd)
		rescue JSON::Schema::ValidationError
			logger.error "JSON validation: #{$!.message}"
			return nsd, $!.message + "\n"
		end

		return nsd, nil
		#errors = JSON::Validator.fully_validate(json_schema, nsd)
	end

	# Checks if a XML message is valid
	#
	# @param [XML] message some XML message
	# @return [Hash, nil] if the parsed message is a valid XML
	# @return [Hash, String] if the parsed message is an invalid XML
	def parse_xml(message)
		# Check XML message format
		begin
			parsed_message = Nokogiri::XML(message) { |config| config.strict }
		rescue Nokogiri::XML::SyntaxError => e
			logger.error "XML parsing: #{e}"
			return message, e
		end

		return parsed_message, nil
	end

	# Checks if a parsed XML message is a valid NSD
	#
	# @param [Hash] nsd the XML message parsed
	# @return [Hash, nil] if the XML message is a valid NSD
	# @return [Hash, String] if the XML message is an invalid NSD
	def validate_xml_nsd(nsd)
		# Read NSD xsd schema
		begin
			xsd = Nokogiri::XML::Schema(File.read(settings.xml_schema))
		rescue Nokogiri::XML::SyntaxError => e
			errors = []
			e.each do |error|
				logger.error "XSD parsing: #{error.message}"
				errors.push(error.message)
			end
			return nsd, errors
		end

		# Validate received XML message against NSD schema
		errors = []
		xsd.validate(nsd).each do |error|
			logger.error "XSD validation: #{e}"
			errors.push(error.message)
		end
		if errors.empty?
			return nsd, nil
		else
			return nsd, errors
		end
	end
end