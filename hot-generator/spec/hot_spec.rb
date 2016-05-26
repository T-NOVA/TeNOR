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

  describe 'POST /hot/:flavour' do
    context 'given an invalid content type' do
      let(:response) { post '/hot/flavor0', {vnfd: {}, networks_id: 'network_id', security_group_id: "security_group_id"}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

      it 'responds with a 415' do
        expect(response.status).to eq 415
      end

      it 'responds with an empty body' do
        expect(response.body).to be_empty
      end
    end

    context 'given an invalid content type' do
      let(:response) { post '/networkhot/flavor0', {vnfd: {}, networks_id: 'network_id'}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

      it 'responds with a 415' do
        expect(response.status).to eq 400
      end

    end

    context 'given a valid VNFD' do

      vnfd = File.read(File.expand_path("../fixtures/vnfd.json", __FILE__))
      networks_id = []
      instance_info = {:vnf => JSON.parse(vnfd), :networks_id => networks_id, :security_group_id => "security_group_id"}

      let(:response) { post '/hot/flavor0', instance_info.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

      it 'responds with a 200' do
        expect(response.status).to eq 200
      end

      it 'response body should contain a Hash (NS)' do
        expect(JSON.parse response.body).to be_a Hash
      end

      it 'response body should be equal' do
        valid_response = File.read(File.expand_path("../fixtures/heat_vnfd_response.json", __FILE__))
        resources = JSON.parse(response.body)['resources']
        resources2 = JSON.parse(valid_response)['resources']
        #expect(resources).to eq(resources2)
      end
    end
  end

end