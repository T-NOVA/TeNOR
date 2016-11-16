require_relative 'spec_helper'

RSpec.describe TnovaManager do

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
		Service.create!({name: "vnf_manager", host: "localhost", port: "4567", path: "", token: JWT.encode({:service_name => 'vnf_manager'}, 'vnf_manager', "HS256"), depends_on: [], type: ""})
	end

	let(:app) {
		Rack::Builder.new do
			eval File.read('config.ru')
		end
	}

	describe 'GET /' do
		context 'given an invalid content type' do
			let(:response) { get '/vnfs' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end

			it 'responds with an empty array' do
				expect(JSON.parse response.body).to be_an Array
			end
		end

		context 'given a valid VNFD' do
			let(:response) { get '/vnfs/5829ac034431124ef1f54ed7' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	describe 'POST /vnfs' do
		skip "is skipped" do
		end
	end

	describe 'PUT /vnfs' do
		skip "is skipped" do
		end
	end

	describe 'DELETE /vnfs' do
		skip "is skipped" do
		end
	end
end
