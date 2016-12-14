require_relative 'spec_helper'

RSpec.describe TnovaManager do

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
		Service.create!({name: "ns_catalogue", host: "localhost", port: "4011", path: "", token: JWT.encode({:service_name => 'ns_catalogue'}, 'ns_catalogue', "HS256"), depends_on: [], type: ""})
	end

	let(:app) {
		Rack::Builder.new do
			eval File.read('config.ru')
		end
	}

	describe 'GET /' do
		context 'given an invalid content type' do
			let(:response) { get '/network-services' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end

			it 'responds with an empty array' do
				expect(JSON.parse response.body).to be_an Array
			end
		end

		context 'given a valid NSD' do
			let(:response) { get '/network-services/5829ac034431124ef1f54ed7' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	describe 'POST /network-services' do
		skip "is skipped" do
		end
	end

	describe 'PUT /network-services' do
		skip "is skipped" do
		end
	end

	describe 'DELETE /network-services' do
		skip "is skipped" do
		end
	end
end
