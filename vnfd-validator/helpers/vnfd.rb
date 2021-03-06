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
# @see VnfdValidatorHelper
module VnfdValidatorHelper
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

  def validate_lifecycle_events(vnfd)
    vnfd['vnf_lifecycle_events'].each do |event|
      event['events'].each do |_type, object|
        if object['template_file'].nil?
          logger.error 'Template file in Lifecycle events is not defined.'
          halt 400, 'Template file in Lifecycle events is not defined.'
        else
          begin
            JSON.parse(object['template_file'])
          rescue JSON::ParserError => e
            logger.error e
            halt 400, 'Lifecycle events template incorrect. JSON parser error. Error: ' + e.to_s
          rescue => e
            logger.error e
            halt 400, 'Lifecycle events template incorrect. Error: ' + e.to_s
          end
        end
      end
    end

    vnfd
  end
end
