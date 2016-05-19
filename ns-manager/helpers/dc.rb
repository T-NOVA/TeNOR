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
module GatekeeperHelper

  # Get list of PoPs
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
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

  # Get list of PoPs
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
  def getPopInfo(popId)
    loginGK()
    popList = getPopList()
    if popList.index(popId).nil?
      halt 400, "Pop id error"
    end
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

  # Get list of PoPs
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
  def getPopUrls(extraInfo)
    urls = extraInfo.split(" ")

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
      end
    end

    return popUrls
  end

end