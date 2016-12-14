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
require_relative 'spec_helper'

RSpec.describe NsProvisioning do
    def app
        Provisioner
    end

    before do
#        begin
#            DatabaseCleaner.start
#        ensure
#            DatabaseCleaner.clean
#        end
    end

    describe 'POST /ns-instances/nsr_id/instantiate' do
        let(:nsr) { create :nsr_example_netfloc }
        context 'when the nsr is found' do
            let(:response_found) { post '/' + nsr._id.to_s + '/instantiate', File.read(File.expand_path('../fixtures/instantiated_info.json', __FILE__)), 'CONTENT_TYPE' => 'application/json'}

			it 'responds with an empty body' do
				expect(response_found.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end

    end
end
