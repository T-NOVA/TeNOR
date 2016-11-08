#
# TeNOR - VNF Provisioning
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
# @see ProvisioningHelper
module UtilsHelper
    # Checks if a JSON message is valid
    #
    # @param [JSON] message some JSON message
    # @return [Hash] the parsed message
    def parse_json(message)
        # Check JSON message format
        begin
            parsed_message = JSON.parse(message) # parse json message
        rescue JSON::ParserError => e
            # If JSON not valid, return with errors
            logger.error "JSON parsing: #{e}"
            halt 400, e.to_s + "\n"
        end

        parsed_message
    end

    # Method which lists all available interfaces
    #
    # @return [Array] an array of hashes containing all interfaces
    def interfaces_list
        [
            {
                uri: '/',
                method: 'GET',
                purpose: 'REST API Structure and Capability Discovery'
            },
            {
                uri: '/vnf-provisioning/vnf-instances',
                method: 'POST',
                purpose: 'Provision a VNF'
            },
            {
                uri: '/vnf-provisioning/vnf-instances/:id/destroy',
                method: 'POST',
                purpose: 'Destroy a VNF'
            }
        ]
    end

    def calculate_event_time(resources, events)
        events.each { |a| puts a }
        resource_stats = []
        resources.each do |resource|
            next unless resource['resource_status'] == 'CREATE_COMPLETE'
            events_resource = events.find_all { |role| role['logical_resource_id'].to_s == resource['logical_resource_id'].to_s }
            event = events_resource.find { |role| role['resource_status'] == 'CREATE_COMPLETE' }
            next if event.nil?
            creation_time = DateTime.parse(resource['creation_time']).to_time.to_i
            final_time = DateTime.parse(event['event_time']).to_time.to_i
            resource_stats << { id: event['logical_resource_id'], type: resource['resource_type'], time: (final_time - creation_time).to_s }
        end
        resource_stats
    end
end
