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
  def getDcs()
    begin
        return Dc.all
    rescue => e
        logger.error e
        logger.error 'Error Establishing a Database Connection'
        return 500, 'Error Establishing a Database Connection'
    end
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
    return dc
  end

  def getDcsTokens()
    dcs_tokens = []
    dcs = Dc.all
    dcs.each do |dc|
      puts dc.inspect
      dcs_tokens << {:id => dc.id, :token => "token"}
    end
    puts dcs_tokens
    halt 200, dcs_tokens.to_json
  end

  # Get list of PoPs
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
  def getPopInfo(pop_id)
    AuthenticationHelper.loginGK()
    begin
      response = RestClient.get "#{settings.gatekeeper}/admin/dc/#{pop_id}", 'X-Auth-Token' => settings.gk_token, :content_type => :json
    rescue RestClient::ResourceNotFound
      halt 404, "PoP not found."
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        error = {:info => "The PoP is not registered in Gatekeeper"}
        halt 503, "The PoP is not registered in Gatekeeper"
      end
    end

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
      elsif key == 'tenant-name'
        popUrls[:tenantname] = item.split('=')[1]
      end
    end

    return popUrls
  end

  def registerPop(pop_info)
    AuthenticationHelper.loginGK()
    begin
      response = RestClient.post "#{settings.gatekeeper}/admin/dc/", pop_info.to_json, 'X-Auth-Token' => settings.gk_token, :content_type => :json
    rescue RestClient::ResourceNotFound
      halt 404, "PoP not found."
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        error = {:info => "The PoP is not registered in Gatekeeper"}
        halt 503, "The PoP is not registered in Gatekeeper"
      end
    end
    return response
  end

end
