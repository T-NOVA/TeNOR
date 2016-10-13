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

        # check authentication, if fails, the PoP is not inserted
        auth = { auth: { tenantName: extrainfo[:tenantname], passwordCredentials: { username: pop_info['adminid'], password: pop_info['password'] } } }
        begin
            response = RestClient.post extrainfo[:keystone] + '/tokens', auth.to_json, content_type: :json
        rescue Errno::ECONNREFUSED => e
            return 500, "Connection refused"
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error e.response.body
            return 400, errors if errors
        end

        authentication, errors = parse_json(response)
        return 400, errors if errors

        # authentication ok, save it to gatekeeper
        registerPop(pop_info)
        return getPopList
    end
end
