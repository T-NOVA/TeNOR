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
# @see NsProvisioner
module PopHelper
    # Returns the information of PoPs
    #
    # @param [String] message the pop id
    # @return [Hash, nil] if the parsed message is a valid JSON
    # @return [Hash, String] if the parsed message is an invalid JSON
    def getPopInfo(pop_id)
        begin
            response = RestClient.get "#{settings.manager}/gatekeeper/dc/#{pop_id}", content_type: :json
        rescue RestClient::ResourceNotFound
            logger.error 'PoP not found.'
            return 400, 'PoP not found.'
        rescue => e
            logger.error e
            puts 'Raise....'
            return 400, 'no exists'
            raise 'Pop id no exists'
        end
        popInfo, errors = parse_json(response)
        return 400, errors if errors

        popInfo
    end

    # Returns the list of URLs of the PoPs
    #
    # @param [JSON] message some JSON message
    # @return [Hash, nil] if the parsed message is a valid JSON
    # @return [Hash, String] if the parsed message is an invalid JSON
    def getPopUrls(extraInfo)
        urls = extraInfo.split(' ')

        popUrls = {}

        for item in urls
            key = item.split('=')[0]
            if key == 'keystone-endpoint'
                popUrls[:keystone] = item.split('=')[1]
            elsif key == 'neutron-endpoint'
                popUrls[:neutron] = item.split('=')[1]
            elsif key == 'compute-endpoint'
                popUrls[:compute] = item.split('=')[1]
            elsif key == 'orch-endpoint'
                popUrls[:orch] = item.split('=')[1]
            elsif key == 'tenant-name'
                popUrls[:tenant] = item.split('=')[1]
            elsif key == 'dns'
                popUrls[:dns] = item.split('=')[1]
            end
        end

        popUrls
    end

    # Returns all the registered PoPs
    #
    # @return [Hash, nil] if the parsed message is a valid JSON
    # @return [Hash, String] if the parsed message is an invalid JSON
    def getPops
        begin
            response = RestClient.get "#{settings.manager}/gatekeeper/dc", content_type: :json
        rescue => e
            logger.error e
            logger.error 'PoP no exists?'
            return 400, 'no exists'
        end
        popInfo, errors = parse_json(response)
        return 400, errors if errors

        logger.error popInfo

        popInfo
    end

    # Returns an object with the properties of a PoP
    # @param [string] The extra information in string
    # @return [Hash] The PoP information in hash format
    def getPoPExtraInfo(extraInfo)
        pop_extra_info = {}
        items = extraInfo.split(' ')
        for item in items
            pop_extra_info[item.split('=')[0]] = item.split('=')[1]
        end
        pop_extra_info
    end
end
