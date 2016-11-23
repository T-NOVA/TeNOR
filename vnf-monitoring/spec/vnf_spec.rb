#
# TeNOR - VNF Monitoring
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

  describe 'POST /ns-monitoring/monitoring-parameters' do
        context 'given an invalid content type' do
            let(:response) { post '/vnf-monitoring/vnfr_id/monitoring-parameters', File.read(File.expand_path('../fixtures/monitoring_request.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' } }

            it 'responds with a 415' do
                expect(response.status).to eq 415
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end

        context 'given a valid Monitoring' do
            let(:response) { post '/vnf-monitoring/vnfr_id/monitoring-parameters', File.read(File.expand_path('../fixtures/monitoring_request.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/json' } }

            it 'responds with a 200' do
                expect(response.status).to eq 200
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end
    end

    describe 'POST /vnf-monitoring/:vnfr_id/readings' do
          context 'given an invalid content type' do
              let(:response) { post '/vnf-monitoring/vnfr_id/readings', File.read(File.expand_path('../fixtures/monitoring_data.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' } }

              it 'responds with a 415' do
                  expect(response.status).to eq 415
              end

              it 'responds with an empty body' do
                  expect(response.body).to be_empty
              end
          end

          context 'given a valid Monitoring' do
              let(:response) { post '/vnf-monitoring/vnfr_id/readings', File.read(File.expand_path('../fixtures/monitoring_data.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/json' } }

              it 'responds with a 200' do
                  expect(response.status).to eq 200
              end

              it 'responds with an empty body' do
                  expect(response.body).to be_empty
              end
          end
      end

      describe 'DELETE /vnf-monitoring/subscription/:vnfr_id' do
            context 'given a valid Monitoring' do
                let(:response) { delete '/vnf-monitoring/subscription/vnfr_id', rack_env = { 'CONTENT_TYPE' => 'application/json' } }

                it 'responds with a 200' do
                    expect(response.status).to eq 200
                end

                it 'responds with an empty body' do
                    expect(response.body).to be_empty
                end
            end
        end
end
