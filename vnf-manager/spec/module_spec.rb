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

RSpec.describe VNFManager do
	def app
		ServiceConfiguration
	end

	before do

	end

	describe 'GET /services' do
		context 'given there are no services'
		let(:response) { get '/services' }

		it 'returns an array' do
			expect(JSON.parse response.body).to be_an Array
		end

		it 'returned array should be empty' do
			expect(JSON.parse response.body).to be_empty
		end

		it 'responds with a 200' do
			expect(response.status).to eq 200
		end

		context 'given there are one or more configs' do
			it 'responds with a 200' do
					expect(response.status).to eq 200
			end
		end
	end

	describe 'GET /modules' do
		let(:obj) { create :service }

		context 'when the config is not found' do
			let(:response_not_found) { get '/services/dasdsaad' }
			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
        expect(response_not_found.status).to eq 404
			end
		end

		context 'when the service is found' do
			let(:response_found) { get '/services/name/' + obj.name }
			it 'response body should not be empty' do
				expect(response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (NS)' do
				expect(response_found.body).to be_a String
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'DELETE /configs' do
		let(:obj) { create :service }
		context 'when the service is not found' do
			let(:response_not_found) { delete '/services/' + 'invalidId' }
			it 'responds with 404' do
				expect(response_not_found.status).to eq 404
			end

			it 'response body should be empty'do
				expect(response_not_found.body).to be_empty
			end
		end

		context 'when the service is found' do
			let(:response) { delete '/services/' + obj.name }
			it 'responds with a 200' do
				expect(response.status).to eq 200
			end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

=begin
describe 'PUT /services/:services_id' do
	context 'given an invalid content type' do
		it 'responds with a 415' do
		end

		it 'responds with an empty body' do
		end
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
=end
end
