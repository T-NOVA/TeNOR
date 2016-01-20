require_relative 'spec_helper'

RSpec.describe OrchestratorNsCatalogue do
	def app
		OrchestratorNsCatalogue
	end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
	end

	describe 'POST /network-services' do
		context 'given an invalid content type' do
			let(:response) { post '/network-services', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid NS' do
			let(:response) { post '/network-services', {nsd: {id: 1, name: 'teste'}}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should contain a Hash (NS)' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end


	describe 'GET /network-services' do
		context 'when there are no NSs' do
			let(:response) { get '/network-services' }

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

		context 'when there are one or more NSs' do
			before { create_pair(:ns) }
			let(:response) { get '/network-services' }

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

	describe 'GET /network-services/:id' do
		let(:ns) { create :ns }

		context 'when the NS is not found' do
			let(:response_not_found) { get '/network-services/' + 'aaa' }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the NS is found' do
      let(:response_found) { get '/network-services/' + ns.nsd[:id] }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (NS)' do
				expect(JSON.parse response_found.body).to be_a Hash
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'DELETE /network-services/:id' do
		let(:ns) { create :ns }

		context 'when the NS is not found' do
			let(:response_not_found) { delete '/network-services/' + ns.nsd[:id] }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with a 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the NS is found' do
			let(:response_found) { delete '/network-services/' + ns._id }

			it 'responds with an empty body' do
				expect(response_found.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'PUT /network-services/:id' do
	end
end