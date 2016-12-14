require_relative 'spec_helper'

RSpec.describe TnovaManager do

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
		Service.create!({name: "ns_monitoring", host: "localhost", port: "4014", path: "", token: JWT.encode({:service_name => 'ns_monitoring'}, 'ns_monitoring', "HS256"), depends_on: [], type: ""})
		Service.create!({name: "vnf_manager", host: "localhost", port: "4567", path: "", token: JWT.encode({:service_name => 'vnf_manager'}, 'vnf_manager', "HS256"), depends_on: [], type: ""})
	end

	let(:app) {
		Rack::Builder.new do
			eval File.read('config.ru')
		end
	}

	describe 'GET /' do
		context 'given an invalid content type' do
			let(:response) { get '/instances/id/monitoring-data/?instance_type=ns' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end

			it 'responds with an empty array' do
				expect(JSON.parse response.body).to be_an Array
			end
		end

		context 'given a valid NSD' do
			let(:response) { get '/instances/id/monitoring-data/?instance_type=vnf' }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response with an empty array' do
				expect(JSON.parse response.body).to be_an Array
			end
		end
	end
end
