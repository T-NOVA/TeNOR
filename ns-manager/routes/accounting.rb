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
class AccountingController < TnovaManager

  # @method put_accounting_servicestatus
  # @overload put '/accounting/servicestatus/:ns_instance_id/:status'
  # Put network service status
  # @param [string]
  put '/servicestatus/:ns_instance_id/:status' do

    provisioner, errors = ServiceConfigurationHelper.get_module('ns_provisioner')
    halt 500, errors if errors

    begin
      response = RestClient.put provisioner.host + request.fullpath, request.body.read, 'X-Auth-Token' => provisioner.token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      #logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end
