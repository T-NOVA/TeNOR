require_relative 'spec_helper'

RSpec.describe TnovaManager do
	def app
		ServiceConfiguration
  end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
	end

	describe 'POST /modules' do
		context 'given an invalid content type' do
			let(:response) { post '/services', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid Service' do
			let(:response) { post '/services', {name: "mAPI", host: "localhost", port: 8080, secret: "secret_ns", depends_on:[]}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 201' do
				expect(response.status).to eq 201
      end

			it 'response body should contain a Hash (Service)' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	describe 'GET /modules' do
		context 'when there are no Services' do
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
    end

		context 'when there are one or more Services' do
			before { create_pair(:service) }
			let(:response) { get '/services' }

			it 'does not return an empty body' do
				expect(JSON.parse response.body).to_not be_empty
			end

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'each array item should be a Hash (Service)' do
				expect(JSON.parse response.body).to all be_a Hash
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end

	describe 'GET /modules/services/:id' do
		let(:obj) { create :service }

		context 'when the Service is not found' do

			let(:response_not_found) { get '/services/' + 'aaa' }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
        expect(response_not_found.status).to eq 404
			end
		end

		context 'when the Service is found' do
      let(:response_found) { get '/services/' + obj._id }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Hash (Service)' do
				expect(JSON.parse response_found.body).to be_a Hash
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'GET /modules/services/name/:name' do
		let(:obj) { create :service }

		context 'when the Service name is not found' do

			let(:response_not_found) { get '/services/name/' + 'aaa' }

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with 404' do
        expect(response_not_found.status).to eq 404
			end
		end

		context 'when the Service is found' do
      let(:response_found) { get '/services/name/' + obj.name }

			it 'response body should not be empty' do
				expect(response_found.body).to_not be_empty
			end

			it 'response body should contain a String (Token)' do
				expect(response_found.body).to be_a String
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'DELETE /modules/services/:id' do
		let(:obj) { create :service }

		context 'when the Services is not found' do
			let(:response_not_found) { delete '/services/' + 'invalidId'}

			it 'responds with an empty body' do
				expect(response_not_found.body).to be_empty
			end

			it 'responds with a 404' do
				expect(response_not_found.status).to eq 404
			end
		end

		context 'when the Services is found' do
			let(:response_found) { delete '/services/' + obj.name }

			it 'responds with an empty body' do
				expect(response_found.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end

	describe 'PUT /modules/services/:id' do
	end
end
