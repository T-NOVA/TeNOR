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
# @see VnfProvisioner
class VnfProvisioner< TnovaManager

  # @method get_vnf_provisioning_instances
  # @overload get "/vnf-provisioning/vnf-instances"
  # Get the VNF instance list
  get '/vnf-instances' do
    manager, errors = ServiceConfigurationHelper.get_module('vnf_manager')
    halt 500, errors if errors

    begin
      response = RestClient.get manager.host + request.fullpath, 'X-Auth-Token' => manager.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  # @method get_vnf_provisioning_instances_id
  # @overload get "/vnf-provisioning/vnf-instances/:vnfr_id"
  # Get a specific vnf-instance
  # @param [string] vnfr_id The VNFR id
  get '/vnf-instances/:vnfr_id' do
    manager, errors = ServiceConfigurationHelper.get_module('vnf_manager')
    halt 500, errors if errors

    begin
      response = RestClient.get manager.host + request.fullpath, 'X-Auth-Token' => manager.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end
