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

RSpec.describe VnfProvisioning do
  def app
    Scaling
  end

  before do
    begin
      DatabaseCleaner.start
    ensure
      DatabaseCleaner.clean
    end
  end

  describe 'POST /vnf-instances/scaling/:vnfr_id/scale_in' do

    context 'given a valid request' do

      it 'provisions a new VNF in the VIM' do
        response = post '/vnfr_id/scale_in', {vnfd: {id: 1}}.to_json, 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq 200
      end
    end
  end

end