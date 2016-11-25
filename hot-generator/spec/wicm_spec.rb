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

  describe 'POST /wicmhot' do
    context 'given an invalid content type' do
      let(:response) { post '/wicmhot', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

      it 'responds with a 415' do
        expect(response.status).to eq 415
      end

      it 'responds with an empty body' do
        expect(response.body).to be_empty
      end
    end

    context 'given a valid NS' do
      wicmhot_request = {
        "physical_network": "sfcvlan",
        "allocated": {
          "ns_instance_id": "service1",
          "ce_transport": {
              "type": "vlan",
              "vlan_id": 400
          },
          "nfvi_id": "nfvi1",
          "pe_transport": {
              "type": "vlan",
              "vlan_id": 401
          }
        }
      }

      let(:response) { post '/wicmhot', wicmhot_request.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

      it 'responds with a 200' do
        expect(response.status).to eq 200
      end

      it 'response body should contain a Hash (NS)' do
        expect(JSON.parse response.body).to be_a Hash
      end

      it 'response body should be equal' do
        valid_response = '{"heat_template_version":"2014-10-16","description":"Resources for WICM and SFC integration","parameters":{},"resources":{"WICM_0":{"type":"OS::Neutron::ProviderNet","properties":{"network_type":"vlan","physical_network":"sfcvlan","segmentation_id":400}},"WICM_1":{"type":"OS::Neutron::ProviderNet","properties":{"network_type":"vlan","physical_network":"sfcvlan","segmentation_id":401}},"WICM_2":{"type":"OS::Neutron::Net","properties":{"name":"WICM_2"}},"WICM_3":{"type":"OS::Neutron::Net","properties":{"name":"WICM_3"}},"WICM_4":{"type":"OS::Neutron::Subnet","properties":{"network_id":{"get_resource":"WICM_0"},"ip_version":4,"cidr":250,"dns_nameservers":["8.8.8.8"]}},"WICM_5":{"type":"OS::Neutron::Subnet","properties":{"network_id":{"get_resource":"WICM_1"},"ip_version":4,"cidr":251,"dns_nameservers":["8.8.8.8"]}},"WICM_6":{"type":"OS::Neutron::Subnet","properties":{"network_id":{"get_resource":"WICM_2"},"ip_version":4,"cidr":252,"dns_nameservers":["8.8.8.8"]}},"WICM_7":{"type":"OS::Neutron::Subnet","properties":{"network_id":{"get_resource":"WICM_3"},"ip_version":4,"cidr":253,"dns_nameservers":["8.8.8.8"]}}},"outputs":{}}'
        expect(JSON.parse response.body).to eq(JSON.parse valid_response)
      end
    end
  end
end
