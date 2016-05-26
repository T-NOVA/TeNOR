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
# @see NsProvisioner
class Scaling < NsProvisioning

  # @method post_ns_instances_scale_out
  # @overload post '/ns-instances/scaling/:id/scale_out'
  # Post a Scale out request
  # @param [JSON]
  post "/:id/scale_out" do

    begin
      instance = Nsr.find(params["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt(404)
    end

    url = @tenor_modules.select {|service| service["name"] == "vnf_manager" }[0]
    instance['vnfrs'].each do |vnf|
      puts vnf

      begin
        response = RestClient.post url['host'].to_s + ":" + url['port'].to_s + '/vnf-instances/scaling/'+vnf['vnfr_id']+'/scale_out', @instance.to_json, :content_type => :json
      rescue => e
        logger.error e
      end

      logger.debug response

    end

    halt 200, "Scale out done."

  end

  # @method post_ns_instances_scale_in
  # @overload post '/ns-instances/scaling/:id/scale_in'
  # Post a Scale in request
  # @param [JSON]
  post "/:id/scale_in" do


  end

end
