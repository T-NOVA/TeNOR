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

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
		Service.create!({name: "vnf_catalogue", host: "localhost", port: "4569", path: "", token: "token", depends_on: [], type: ""})
	end

	let(:app) {
		Rack::Builder.new do
			eval File.read('config.ru')
		end
	}

	describe 'GET /' do
		let(:response) { get '/vnfs' }

		it 'responds with a 200' do
			expect(response.status).to eq 200
		end

		it 'responds with an Array' do
			expect(JSON.parse response.body).to be_an Array
		end

		it 'each array item should be a Hash (Interface description)' do
			expect(JSON.parse response.body).to all be_a Hash
		end
	end

	describe 'GET /vnfs' do
		context 'when there are no VNFs' do
			let(:response) { get '/vnfs' }

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'returned array should be empty' do
				expect(JSON.parse response.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end

	describe 'POST /vnfs' do
		context 'given an invalid content type' do
			let(:vnf) { build(:vnf) }
			let(:response) { post '/vnfs', vnf.marshal_dump.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given an invalid VNF' do
			let(:vnf) { build(:invalid_vnf) }
			let(:response) { post '/vnfs', vnf.marshal_dump.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 400' do
				expect(response.status).to eq 400
			end

			it 'response body should not be empty (contains error messages)' do
				expect(response.body).to_not be_empty
			end
		end

		context 'given a valid VNF' do
			let(:vnf) { build(:vnf) }
			let(:response) { post '/vnfs', vnf.marshal_dump.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end

			it 'response body should contain a Hash (VNF)' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end

	end
=begin
	describe 'GET /vnfs' do
		context 'when there are one or more VNFs' do
			let(:response) { get '/' }

			it 'does not return an empty body' do
				expect(JSON.parse response.body).to_not be_empty
			end

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'each array item should be a Hash (VNF)' do
				expect(JSON.parse response.body).to all be_a Hash
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end

	describe 'GET /vnfs/:external_vnf_id' do
		let(:vnf_list) { JSON.parse (get '/').body }

		context 'when the VNF is not found' do
			let(:response_not_found) { get '/' + (vnf_list.last['_id'].to_i + 1).to_s }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the VNF is found' do
			let(:response_found) { get '/' + vnf_list.last['_id'] }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (VNF)' do
				expect(JSON.parse response_found.body).to be_a Hash
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end
=begin
	describe 'DELETE /vnfs/:external_vnf_id' do
		let(:vnf_list) { JSON.parse (get '/vnfs').body }

		context 'when the VNF is not found' do
			let(:response_not_found) { delete '/vnfs/' + (vnf_list.last['_id'].to_i + 1).to_s }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with a 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the VNF is found' do
			let(:response_found) { delete '/vnfs/' + vnf_list.last['_id'] }

			it 'responds with an empty body' do
				expect(response_found.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'PUT /vnfs/:external_vnf_id' do
	end
=end
end
