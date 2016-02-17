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
class TnovaManager < Sinatra::Application

  def getPopList()

    begin
      response = RestClient.get "#{settings.gatekeeper}/admin/dc/", 'X-Auth-Token' => settings.gk_token, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        error = {:info => "The PoP list in Gatekeeper is empty"}
        halt 503, "The PoP list in Gatekeeper is empty "
      end
    end
    popList, errors = parse_json(response.body)
    return 400, errors if errors

    return popList['dclist']
  end

  def getPopInfo(popId)
    loginGK()
    popList = getPopList()
    pop_id = popList.index(popId) + 1

    begin
      response = RestClient.get "#{settings.gatekeeper}/admin/dc/#{pop_id}", 'X-Auth-Token' => settings.gk_token, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        error = {:info => "The PoP is not registered in Gatekeeper"}
        halt 503, "The PoP is not registered in Gatekeeper"
      end
    end
    #popInfo, errors = parse_json(response.body)
    #return 400, errors if errors

    return response
  end


end