#
# TeNOR - VNF Manager
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

RSpec.describe OrchestratorVnfManager do
	def app
		OrchestratorVnfManager
	end

	describe 'POST /vnf-instances' do
		context 'given an invalid content type' do
			it 'responds with a 415'

			it 'response body should be empty'
		end

		context 'given a invalid request' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'given a valid request' do
			it 'responds with a 200'

			it 'response body should contain a Hash'
		end
	end

	describe 'PUT /vnf-instances/:vnf_instance_id' do
		context 'given an invalid content type' do
			it 'responds with a 415'

			it 'response body should be empty'
		end

		context 'given the vnf instance is not found' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'given the vnf instance is found' do
			it 'responds with a 200'

			it 'response body should be empty'
		end
	end

	describe 'DELETE /vnf-instances/:vnf_instance_id' do
		context 'when the vnf instance is not found' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'when the vnf-instances is found' do
			it 'responds with a 200'

			it 'response body should be empty'
		end
	end

	describe 'GET /vnf-instances/:vnf_instance_id' do
		context 'when the vnf instance is not found' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'when the vnf-instances is found' do
			it 'responds with a 200'

			it 'response body should be a Hash'
		end
	end

	describe 'GET /vnf-instances' do
		context 'when there are no vnf instances' do
			it 'responds with a 200'

			it 'response body should be an Array'

			it 'response Array should be empty'
		end

		context 'when there are one or more vnf-instances' do
			it 'responds with a 200'

			it 'response body should be an Array'

			it 'all response Array items should be a Hash'
		end
	end
end