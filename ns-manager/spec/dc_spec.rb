require_relative 'spec_helper'

RSpec.describe TnovaManager do
	def app
		DcController
  end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
	end

	describe 'POST /pops' do
		context 'given an invalid content type' do
			let(:response) { post '/dc', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid DC' do
			host = "openstack_ip"
			let(:response) { post '/dc', {name: "name", host: "openstack_ip", user: "user", password: "", tenant_name: "tenan", extra_info: "keystone-endpoint=http://#{host}:35357/v2.0 orch-endpoint=http://#{host}:8004/v1 compute-endpoint=http://#{host}:8774/v2.1 neutron-endpoint=http://#{host}:9696/v2.0 dns=dns"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 201' do
				expect(response.status).to eq 201
      end

			it 'response body should contain a Hash (DC)' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	describe 'GET /pops' do
		context 'when there are no DCs' do
			let(:response) { get '/dc' }

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

		context 'when there are one or more DCs' do
			before { create_pair(:dc) }
			let(:response) { get '/dc' }

			it 'does not return an empty body' do
				expect(JSON.parse response.body).to_not be_empty
			end

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'each array item should be a Hash (NS)' do
				expect(JSON.parse response.body).to all be_a Hash
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end

	describe 'GET /pops/dc/:id' do
		let(:dc) { create :dc }

		context 'when the DC is not found' do

			let(:response_not_found) { get '/dc/' + 'aaa' }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
        expect(response_not_found.status).to eq 404
			end
		end

		context 'when the DC is found' do
      let(:response_found) { get '/dc/' + dc._id.to_s }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (DC)' do
				expect(JSON.parse response_found.body).to be_a Hash
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'GET /pops/dc/name/:id' do
		let(:dc) { create :dc }

		context 'when the DC name is not found' do

			let(:response_not_found) { get '/dc/name/' + 'aaa' }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
        expect(response_not_found.status).to eq 404
			end
		end

		context 'when the DC is found' do
      let(:response_found) { get '/dc/name/' + dc.name }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (DC)' do
				expect(JSON.parse response_found.body).to be_a Hash
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'DELETE /pops/dc/:id' do
		let(:dc) { create :dc }

		context 'when the DC is not found' do
			let(:response_not_found) { delete '/dc/' + 'invalidId'}

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with a 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the DC is found' do
			let(:response_found) { delete '/dc/' + dc._id.to_s }

			it 'responds with an empty body' do
				expect(response_found.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'PUT /dc/:id' do
		let(:dc) { create :dc }

		context 'given an invalid content type' do
			let(:response) { put '/dc/' + dc._id.to_s, {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given an invalid DC id' do
			let(:response) { put '/dc/invalidId', {name: "name", host: "host", user: "user", password: "", tenant_name: "tenan", extra_info: "extra..."}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 404' do
				expect(response.status).to eq 404
      end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid DC' do
			let(:response) { put '/dc/' + dc._id.to_s, {name: "name222", host: "host222", user: "user", password: "", tenant_name: "tenan", extra_info: "extra..."}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid DC' do
			let(:response) { get '/dc/' + dc._id.to_s }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should contain a Hash (DC)' do
				expect(JSON.parse response.body).to be_a Hash
			end

			it 'response body should be equal than the PUT request' do
				skip "is skipped" do
				end
			end

		end
	end
end
