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
            response = RestClient.get compute_url + "/#{tenant_id}/flavors" + query_params, 'X-Auth-Token' => auth_token, :accept => :json
        rescue Errno::ECONNREFUSED
        # halt 500, 'VIM unreachable'
        rescue RestClient::ExceptionWithResponse => e
                 puts "Excepion with response"
                 puts e
                 return e.response.code, e.response.body
        rescue => e
            logger.error e
            # logger.error e.response
            return 400, e
            # halt e.response.code, e.response.body
        end
        [response, nil]
      end

    def get_vdu_flavour(vdu, compute_url, tenant_id, auth_token)
        minDisk = vdu['resource_requirements']['storage']['size']
        minRam = vdu['resource_requirements']['memory'] * 1000
        retries = 0
        retries_max = 10
        query_params = "?minDisk=#{minDisk}&minRam=#{minRam}"
        flavors, errors = get_list_flavors(compute_url, tenant_id, query_params, auth_token)
        logger.info flavors
        logger.error errors if errors
        return 400, 'Error getting flavours.' if errors
        flavors, errors = parse_json(flavors)
        logger.error errors if errors
        return flavors['flavors'][0]['name'], nil unless flavors['flavors'].empty?

        static_disk = nil
        static_ram = nil
        while retries < retries_max
            query_params = "?minDisk=#{minDisk}"
            flavors_disk = get_list_flavors(compute_url, tenant_id, query_params, auth_token)
            if !flavors['flavors'].empty?
                puts 'Disk size has flavours'
                minRam /= 2
                query_params = "?minRam=#{minRam}"
                flavors_disk = get_list_flavors(compute_url, tenant_id, query_params, auth_token)
                return flavors['flavors'][0]['name'], nil
            else
                minDisk /= 2
            end
            retries += 1
        end
        puts 'Raise??'
        return 400, 'Flavor not found.'
    end
end
