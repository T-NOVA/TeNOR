#
# TeNOR - VNF Provisioning
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
# @see ComputeHelper
module ComputeHelper
  def get_list_flavors(compute_url, tenant_id, query_params, auth_token)
        begin
            response = RestClient.get compute_url +"/#{tenant_id}/flavors" + query_params, 'X-Auth-Token' => auth_token, :accept => :json
        rescue Errno::ECONNREFUSED
        # halt 500, 'VIM unreachable'
        rescue RestClient::ResourceNotFound
            logger.error 'Already removed from the VIM.'
            return 404
        rescue => e
          logger.error e
            #logger.error e.response
            return
            # halt e.response.code, e.response.body
        end
        response
    end

    def get_vdu_flavour(vdu, compute_url, tenant_id, auth_token)

        minDisk = vdu['resource_requirements']['storage']['size']
        minRam = vdu['resource_requirements']['memory']*1000
        retries = 0
        retries_max = 10
        query_params = "?minDisk=#{minDisk}&minRam=#{minRam}"
        flavors = JSON.parse(get_list_flavors(compute_url, tenant_id, query_params, auth_token))
        if flavors['flavors'].size > 0
            return flavors['flavors'][0]['name']
        end

        static_disk = nil
        static_ram = nil
        while retries < retries_max do
            query_params = "?minDisk=#{minDisk}"
            puts query_params
            flavors_disk = get_list_flavors(compute_url, tenant_id, query_params, auth_token)
            if flavors['flavors'].size > 0
              puts "Disk size has flavours"
                minRam = minRam/2
                query_params = "?minRam=#{minRam}"
                puts query_params
                flavors_disk = get_list_flavors(compute_url, tenant_id, query_params, auth_token)
                return flavors['flavors'][0]['name']
            else
                minDisk = minDisk/2
            end
            retries +=1
        end
        puts "Raise??"
        raise "Flavor not found."
    end
end
