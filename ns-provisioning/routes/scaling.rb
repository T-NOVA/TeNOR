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
# @see OrchestratorNsProvisioner
class NsProvisioner < Sinatra::Application

  post "/ns-instances/scaling/:nsr_id/scale_out" do

    url = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]
    begin
      response = RestClient.get url['host'].to_s + ":" + url['port'].to_s + '/ns-instances/' + params['nsr_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    instance, errors = parse_json(response)
    puts instance

    url = @tenor_modules.select {|service| service["name"] == "vnf_manager" }[0]
    instance['vnfrs'].each  do |vnf|
      puts vnf

      begin
        response = RestClient.post url['host'].to_s + ":" + url['port'].to_s + '/vnf-instances/scaling/'+vnf['vnfr_id']+'/scale_out', @instance.to_json, :content_type => :json
      rescue => e
        logger.error e
      end
    end

    halt 200, "Scale out done."

  end

  post "/ns-instances/scaling/:nsr_id/scale_in" do


  end

end
