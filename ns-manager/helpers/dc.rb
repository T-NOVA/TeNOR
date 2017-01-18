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
# @see ApplicationHelper
module DcHelper
    # Get list of PoPs
    #
    # @param [Symbol] format the format type, `:text` or `:html`
    # @return [String] the object converted into the expected format.
    def getDcs
        return Dc.all
    rescue => e
        logger.error e
        logger.error 'Error Establishing a Database Connection'
        return 500, 'Error Establishing a Database Connection'
    end

    # Get a PoP
    #
    # @param [Symbol] format the format type, `:text` or `:html`
    # @return [String] the object converted into the expected format.
    def getDc(id)
        begin
            dc = Dc.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'DC not found'
            return nil
        end
        dc
    end

    def getDcsTokens
        dcs_tokens = []
        dcs = Dc.all
        dcs.each do |dc|
            dcs_tokens << { id: dc.id, token: 'token' }
        end
        halt 200, dcs_tokens.to_json
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
    
    # Return the status of a PoP
    def popStatus(pop_info)
        keystone_url = getPoPExtraInfo(pop_info[:extra_info])['keystone']
        tenant_name = pop_info[:tenant_name]
        username = pop_info[:user]
        password = pop_info[:password]
        keystone_version = URI(keystone_url).path.split('/').last
        if keystone_version == 'v2.0'
            user_authentication, errors = authentication_v2(keystone_url, tenant_name, username, password)
            logger.error errors if errors
            return 400, errors.to_json if errors
            tenant_id = user_authentication['access']['token']['tenant']['id']
            user_id = user_authentication['access']['user']['id']
            token = user_authentication['access']['token']['id']
        elsif keystone_version == 'v3'
            user_authentication, errors = authentication_v3(keystone_url, tenant_name, username, password)
            logger.error errors if errors
            return 400, errors.to_json if errors
            if !user_authentication['token']['project'].nil?
                tenant_id = user_authentication['token']['project']['id']
                user_id = user_authentication['token']['user']['id']
                token = user_authentication['token']['id']
            else
                errors = 'No project found with the provided credentials.'
                return 400, errors.to_json if errors
            end
        end

        # get API version list
        api_version = {}
        begin
            api_version = JSON.parse RestClient.get keystone_url, :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            puts e
        end

        return 200, JSON.pretty_generate(api_version)
    end
end
