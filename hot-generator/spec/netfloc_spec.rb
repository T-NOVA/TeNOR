#
# TeNOR - HOT Generator
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

RSpec.describe HotGenerator do
  def app
    HotGenerator
  end

  describe 'POST /netfloc' do
    context 'given an invalid content type' do
      let(:response) { post '/netfloc', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

      it 'responds with a 415' do
        expect(response.status).to eq 415
      end

      it 'responds with an empty body' do
        expect(response.body).to be_empty
      end
    end

    context 'given a valid NS' do
      netfloc_request = {ports: ["08fb386a-063f-4951-9e7b-3273e990542a", "08fb386a-063f-4951-9e7b-3273e990542b"], odl_username: "odl", odl_password: "pass", netfloc_ip_port: "10.10.10.10"}

      let(:response) { post '/netfloc', netfloc_request.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

      it 'responds with a 200' do
        expect(response.status).to eq 200
      end

      it 'response body should contain a Hash (NS)' do
        expect(JSON.parse response.body).to be_a Hash
      end

      it 'response body should be equal' do
        valid_response = '{"heat_template_version":"2014-10-16","description":"Resources for Netfloc integration","parameters":{},"resources":{"Netfloc_0":{"type":"Netfloc::Service::Chain","properties":{"neutron_ports":["08fb386a-063f-4951-9e7b-3273e990542a", "08fb386a-063f-4951-9e7b-3273e990542b"],"odl_username":"odl","odl_password":"pass","netfloc_ip_port":"10.10.10.10"}}},"outputs":{}}'
        expect(JSON.parse response.body).to eq(JSON.parse valid_response)
      end
    end
  end
end
