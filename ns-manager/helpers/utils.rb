#
# TeNOR - NS Manager
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
# @see TnovaManager
# class TnovaManager < Sinatra::Application
module ApplicationHelper
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
            logger.error "JSON parsing: #{e}"
            return message, e.to_s + "\n"
        end

        [parsed_message, nil]
    end

    # Method which lists all available interfaces
    #
    # @return [Array] the array containing a list of all interfaces
    def interfaces_list
        [
            {
                'uri' => '/',
                'method' => 'GET',
                'purpose' => 'REST API Structure and Capability Discovery'
            },
            {
                'uri' => '/network-services',
                'method' => 'GET',
                'purpose' => 'Get list of Network Services'
            },
            {
                'uri' => '/network-services/{id}',
                'method' => 'GET',
                'purpose' => 'Get a Network Service'
            },
            {
                'uri' => '/network-services',
                'method' => 'POST',
                'purpose' => 'Create a new Network Service'
            },
            {
                'uri' => '/network-services/{id}',
                'method' => 'PUT',
                'purpose' => 'Update a new Network Service'
            },
            {
                'uri' => '/network-services/{id}',
                'method' => 'DELETE',
                'purpose' => 'Delete a new Network Service'
            },
            {
                'uri' => '/vnfs',
                'method' => 'GET',
                'purpose' => 'Get list of VNFs'
            },
            {
                'uri' => '/vnfs',
                'method' => 'POST',
                'purpose' => 'Create a new VNFs'
            },
            {
                'uri' => '/vnfs/{id}',
                'method' => 'PUT',
                'purpose' => 'Update a VNF'
            },
            {
                'uri' => '/ns-instances',
                'method' => 'POST',
                'purpose' => 'Create an instance request'
            },
            {
                'uri' => '/ns-instances',
                'method' => 'GET',
                'purpose' => 'Get list of instances'
            },
            {
                'uri' => '/ns-instances/{id}',
                'method' => 'GET',
                'purpose' => 'Get a ns instances'
            },
            {
                'uri' => '/ns-instances/{id}',
                'method' => 'GET',
                'purpose' => 'Get a ns instances'
            },
            {
                'uri' => '/statistics/generic',
                'method' => 'GET',
                'purpose' => 'Get generic statistics'
            },
            {
                'uri' => '/statistics/performance_stats',
                'method' => 'GET',
                'purpose' => 'Get performance of the instatiation time'
            },
            {
                'uri' => '/gatekeeper/dc',
                'method' => 'GET',
                'purpose' => 'Get list of Data centers'
            },
            {
                'uri' => '/ns-instances/scaling/{nsr_id}/scale_out',
                'method' => 'POST',
                'purpose' => 'Scale out a ns instance'
            },
            {
                'uri' => '/ns-instances/scaling/{nsr_id}/scale_in',
                'method' => 'POST',
                'purpose' => 'Scale in a ns instance'
            },
            {
                'uri' => '/configs/registerService',
                'method' => 'POST',
                'purpose' => 'Register a service configuration'
            },
            {
                'uri' => '/configs/unRegisterService/{microservice}',
                'method' => 'POST',
                'purpose' => 'Unregister a service configuration'
            },
            {
                'uri' => '/configs/services',
                'method' => 'GET',
                'purpose' => 'List all services configuration'
            },
            {
                'uri' => '/configs/services',
                'method' => 'PUT',
                'purpose' => 'Update service configuration'
            },
            {
                'uri' => '/configs/services/{name}/status',
                'method' => 'PUT',
                'purpose' => 'Update service status'
            }
        ]
    end
end
