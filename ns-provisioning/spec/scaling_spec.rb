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
        Scaling
    end

    before do
        begin
            DatabaseCleaner.start
        ensure
            DatabaseCleaner.clean
        end
    end

    describe 'POST /ns-instances/scaling/:nsr_id/scale_out' do
        context 'given a valid request' do
            it 'provisions a new NS in the VIM' do
                # response = post '/nsr_id/scale_in', {nsd: {id: 1}}.to_json, 'CONTENT_TYPE' => 'application/json'
                # expect(last_response.status).to eq 200
            end
        end
    end

    describe 'POST /ns-instances/scaling' do
        context 'given an invalid content type' do
            it 'responds with a 415' do
                post '/invalid/scale_out', {}.to_json, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
                expect(last_response.status).to eq 415
            end
        end

        context 'given an invalid nsr_id' do
            it 'responds with a 404' do
                post '/invalid/scale_out', {}.to_json, 'CONTENT_TYPE' => 'application/json'
                expect(last_response.status).to eq 404
            end
        end
    end

    describe 'POST /ns-instances/scaling' do
      let(:nsr) { create :nsr }
        context 'given an invalid scaling request' do
            it 'responds with a 404' do
                post '/invalid/scale_out', {}.to_json, 'CONTENT_TYPE' => 'application/json'
                expect(last_response.status).to eq 404
            end
        end

        context 'given a valid request' do
            it 'scale_out a NS' do
                response = post '/'+ nsr._id.to_s + '/scale_out', File.read(File.expand_path('../fixtures/scaling_out_request.json', __FILE__)), 'CONTENT_TYPE' => 'application/json'
                expect(last_response.status).to eq 200
            end
        end
    end

    describe 'POST /ns-instances/scaling' do
        context 'given an invalid content type' do
            it 'responds with a 415' do
                post '/invalid/scale_in', {}.to_json, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
                expect(last_response.status).to eq 415
            end
        end

        context 'given an invalid nsr_id' do
            it 'responds with a 404' do
                post '/invalid/scale_in', {}.to_json, 'CONTENT_TYPE' => 'application/json'
                expect(last_response.status).to eq 404
            end
        end
    end

    describe 'POST /ns-instances/scaling' do
      let(:nsr) { create :nsr }
        context 'given an invalid scaling request' do
            it 'responds with a 404' do
                post '/invalid/scale_in', {}.to_json, 'CONTENT_TYPE' => 'application/json'
                expect(last_response.status).to eq 404
            end
        end

        context 'given a valid request' do
            it 'scale_in a NS' do
                response = post '/'+ nsr._id.to_s + '/scale_in', File.read(File.expand_path('../fixtures/scaling_out_request.json', __FILE__)), 'CONTENT_TYPE' => 'application/json'
                puts last_response
                expect(last_response.status).to eq 200
            end
        end
    end
end
