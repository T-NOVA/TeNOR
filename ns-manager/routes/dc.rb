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
# @see GatekeeperController
class GatekeeperController < TnovaManager
    # @method get_gatekeeper_dc
    # @overload get '/gatekeeper/dc/:id'
    #	Returns a DCs
    get '/dc/:popId' do |pop_id|
        return getPopInfo(pop_id)
    end

    # @method get_gatekeeper_dcs
    # @overload get '/gatekeeper/dc'
    #	Returns a list of DCs
    get '/dc' do
        return getPopList
    end

    # @method post_gatekeeper_dcs
    # @overload post '/gatekeeper/dc'
    #	Returns if the DC is correct inserted
    post '/dc' do
        pop_info, errors = parse_json(request.body.read)
        extrainfo = getPopUrls(pop_info['extrainfo'])

        #analyze Keystone version
        version = URI(extrainfo[:keystone]).path.split('/').last

        #v2.0 authentication
        if version == 'v2.0'
            response, errors = authentication_v2(pop_info, extrainfo)
            return 400, errors if errors
        elsif version == 'v3'
            response, errors = authentication_v3(pop_info, extrainfo)
            return 400, errors if errors
        else
            halt 400, "No keystone version specified."
        end
        # authentication ok, save it to gatekeeper
        response, errors = registerPop(pop_info)
        logger.error if errors
        return 400, errors if errors

        pop_info, errors = parse_json(response)
        return pop_info['info'][0]['id']

        return getPopList
    end

    # @method delete_gatekeeper_dc_id
    # @overload get '/gatekeeper/dc/:id'
    #	Delete a DC
    delete '/dc/:popId' do |pop_id|
        AuthenticationHelper.loginGK
        begin
            response = RestClient.delete "#{settings.gatekeeper}/admin/dc/#{pop_id}", 'X-Auth-Token' => settings.gk_token, :content_type => :json
        rescue => e
            logger.error e
            if defined?(e.response).nil?
                error = { info: 'The PoP list in Gatekeeper is empty' }
                halt 503, 'The PoP list in Gatekeeper is empty '
            end
        end
    end
end
