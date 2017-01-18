#
# TeNOR - NS Provisioning
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
# @see MappingHelper
module MappingHelper
    # Call the Service Mapping for service allocation
    #
    # @param [JSON] Microservice information
    # @return [Hash, nil] if the parsed message is a valid JSON
    # @return [Hash, String] if the parsed message is an invalid JSON
    def callMapping(mapping_host, ms)
        begin
            response = RestClient.post mapping_host, ms.to_json, content_type: :json
            # response = RestClient.post settings.mapping + '/mapper', ms.to_json, content_type: :json
        rescue => e
            logger.error e
            if defined?(e.response).nil?
                # halt 400, "NS-Mapping unavailable"
            end
            logger.error e.response
            return 500, 'Service Mapping error.'
            # halt e.response.code, e.response.body
        end
        logger.info response

        mapping, errors = parse_json(response.body)
        return 400, errors if errors

        mapping
    end

    # When the Mapping is not required, only one pop or is selected manually, use the same format for the response
    def getMappingResponse(nsd, pop_id)
        vnf_mapping = []
        nsd['vnfds'].each do |vnf_id|
            vnf_mapping << { 'maps_to_PoP' => "/pop/#{pop_id}", 'vnf' => '/' + vnf_id.to_s }
        end

        mapping = {
            'created_at' => 'Thu Nov  5 10:13:25 2015',
            'links_mapping' =>
            [
                {
                    'vld_id' => 'vld1',
                    'maps_to_link' => '/pop/link/85b0bc34-dff0-4399-8435-4fb2ed65790a'
                }
            ],
            'vnf_mapping' => vnf_mapping
        }
        mapping
    end

    def replace_pop_name_by_pop_id(mapping, pops)
        mapping['vnf_mapping'].each do |m|
            found_pops = pops.find{ |q| q['name'] ==  m['maps_to_PoP'].split("/pop/")[1] }
            puts found_pops
            if found_pops.nil?
                return 400, "The PoP from Mapping cannot be matched to a PoP in TeNOR."
            else
                m['maps_to_PoP'] = "/pop/" + pops.find{ |q| q['name'] ==  m['maps_to_PoP'].split("/pop/")[1] }['id'].to_s
            end
        end
        mapping
    end

    def getMappingResponseWithPops(mapping)
        vnf_mapping = []
        mapping.each_pair do |vnf_id, pop_id|
            vnf_mapping << { 'maps_to_PoP' => "/pop/#{pop_id}", 'vnf' => '/' + vnf_id.to_s }
        end

        mapping = {
            'links_mapping' =>
            [
                {
                    'vld_id' => 'vld1',
                    'maps_to_link' => '/pop/link/85b0bc34-dff0-4399-8435-4fb2ed65790a'
                }
            ],
            'vnf_mapping' => vnf_mapping
        }
        mapping
    end
end
