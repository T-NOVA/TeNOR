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
require_relative 'spec_helper'

RSpec.describe VNFMonitoring do
  def app
    VNFMonitoring
  end

  describe 'GET /vnf-monitoring/instances/:instance_id/monitoring-data/', type: :request do

    it "should redirect to dashboard" do

      file_response = File.new './spec/file_response.json'
      stub_request(:get, '/vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf').to_return(:body => file_response)
      stub_request(:get, "http://vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

      RestClient.get("http://vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf")
    end

  end


end