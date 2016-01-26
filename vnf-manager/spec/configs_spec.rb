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

	describe 'PUT /configs/:config_id' do
		context 'given an invalid content type' do
			it 'responds with a 415'

			it 'response body should be empty'
		end

		context 'given an invalid Service ID' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'given a valid Service ID' do
			it 'responds with a 200'

			it 'response body should be empty'
		end
	end

	describe 'GET /configs' do
		context 'given there are no configs'

		context 'given there are one or more configs' do
			it 'responds with a 200'

			it 'response body should be a Hash'
		end
	end

	describe 'GET /configs/:config_id' do
		context 'when the config is not found' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'when the config is found' do
			it 'responds with a 200'

			it 'response body should be a Hash'
		end
	end

	describe 'DELETE /configs/:config_id' do
		context 'when the config is not found' do
			it 'responds with a 400'

			it 'response body should be empty'
		end

		context 'when the config is found' do
			it 'responds with a 200'

			it 'response body should be empty'
		end
	end
end