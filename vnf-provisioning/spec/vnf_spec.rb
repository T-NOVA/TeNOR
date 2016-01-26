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

RSpec.describe OrchestratorVnfProvisioning do
  def app
    OrchestratorVnfProvisioning
  end

  describe 'GET /' do
    it 'returns the interface list description' do
      c = OrchestratorVnfProvisioning.new
      get '/'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq c.helpers.interfaces_list.to_json
    end
  end

  describe 'POST /vnf-provisioning/vnf-instances' do
    context 'given an invalid content type' do
      it 'responds with a 415' do
        post '/vnf-provisioning/vnf-instances', {}.to_json, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
        expect(last_response.status).to eq 415
      end
    end
    context 'given a valid request' do
      it 'provisions a new VNF in the VIM' do
        response = post '/vnf-provisioning/vnf-instances', {vnf: {id: 1}}.to_json, 'CONTENT_TYPE' => 'application/json'
        puts response.inspect
        expect(last_response.status).to eq 200
      end
    end
  end

  describe 'post /vnf-provisioning/vnf-instances/:id/destroy' do
    pending
  end
end