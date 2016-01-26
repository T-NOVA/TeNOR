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

	# Checks if a parsed JSON message is a valid VNFD
	#
	# @param [Hash] vnfd the JSON message parsed
	# @return [Hash] if the JSON message is a valid VNFD
	def validate_json_vnfd(vnfd)
		# Read VNFD json schema
		json_schema = File.read(settings.json_schema)
		begin
			JSON::Validator.validate!(json_schema, vnfd)
		rescue JSON::Schema::ValidationError
			logger.error "JSON validation: #{$!.message}"
			halt 400, $!.message + "\n"
		end

		vnfd
	end

	# Checks if a XML message is valid
	#
	# @param [XML] message some XML message
	# @return [Hash] if the parsed message is a valid XML
	def parse_xml(message)
		# Check XML message format
		begin
			parsed_message = Nokogiri::XML(message) { |config| config.strict }
		rescue Nokogiri::XML::SyntaxError => e
			logger.error "XML parsing: #{e}"
			halt 400, e
		end

		parsed_message
	end

	# Checks if a parsed XML message is a valid VNFD
	#
	# @param [Hash] vnfd the XML message parsed
	# @return [Hash] if the XML message is a valid VNFD
	def validate_xml_vnfd(vnfd)
		# Read VNFD xsd schema
		begin
			xsd = Nokogiri::XML::Schema(File.read(settings.xml_schema))
		rescue Nokogiri::XML::SyntaxError => e
			errors = []
			e.each do |error|
				logger.error "XSD parsing: #{error.message}"
				errors.push(error.message)
			end
			halt 400, errors
		end

		# Validate received XML message against VNFD schema
		errors = []
		xsd.validate(vnfd).each do |error|
			logger.error "XSD validation: #{e}"
			errors.push(error.message)
		end
		halt 400, errors unless errors.empty?

		vnfd
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
				'uri' => '/vnfds',
				'method' => 'POST',
				'purpose' => 'Validate a VNFD'
			}
		]
	end

	# Verify if the VDU images are accessible to download
	#
	# @param [Array] List of all VDUs of the VNF
	def verify_vdu_images(vdus)
		vdus.each do |vdu|
			logger.debug 'Verifying image: ' + vdu['vm_image'].to_s + ' from ' + vdu['id'].to_s
			begin
				unless RestClient.head(vdu['vm_image']).code == 200
					logger.error "Image #{vdu['vm_image']} from #{vdu['id']} not found."
					halt 400, "Image #{vdu['vm_image']} from #{vdu['id']} not found."
				end
			rescue => e
				logger.error "Image #{vdu['vm_image']} from #{vdu['id']} not accessible."
				halt 400, "Image #{vdu['vm_image']} from #{vdu['id']} not accessible."
			end
		end
	end
end