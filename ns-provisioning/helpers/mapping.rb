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
  def callMapping(ms)

    begin
      response = RestClient.get settings.manager + '/network-services/' + ms[:NS_id], :content_type => :json
    rescue Errno::ECONNREFUSED
      return "Connection refused"
    rescue => e
      return "Error"
      return e.response.code, e.response.body
    end

    nsd, errors = parse_json(response)
    mapping = {
        "created_at" => "Thu Nov  5 10:13:25 2015",
        "links_mapping" =>
          [
              {
                  "vld_id" => "vld1",
                  "maps_to_link" => "/pop/link/85b0bc34-dff0-4399-8435-4fb2ed65790a"
              }
          ],
        "vnf_mapping" =>
            [
                {
                    "maps_to_PoP" => "/pop/1dc4dbf7-2fb3-4acb-96fe-330306f78422",
                    "vnf" => "/" + nsd['vnfds'][0].to_s
                }
            ]
    }

    unsuccessfullMapping = {
        "Error" => "Error in MIP problem",
        "Info" => "MIP solution is undefined",
        "created_at" => "Thu Nov  5 10:11:37 2015"
    }

    if ms[:development]
      return mapping
    end

    begin
      response = RestClient.post settings.ns_mapping + '/mapper', ms.to_json, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        #halt 400, "NS-Mapping unavailable"
      end
      #halt e.response.code, e.response.body
    end

    mapping, errors = parse_json(response.body)
    return 400, errors if errors

    return mapping
  end

end