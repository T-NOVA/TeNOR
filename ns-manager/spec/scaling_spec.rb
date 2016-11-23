require_relative 'spec_helper'

RSpec.describe TnovaManager do
	def app
		NsScaling
  end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
		Service.create!({name: "ns_provisioner", host: "localhost", port: "4012", path: "", token: JWT.encode({:service_name => 'ns_provisioner'}, 'ns_provisioner', "HS256"), depends_on: [], type: ""})
	end

	describe 'POST /ns-instances/scaling/' do
		context 'given an invalid content type' do
			let(:response) { post '/invalid_id/scale_out', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid NS instance' do
			let(:response) { post '/5825ce99c098a434c100000c/scale_out', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

	describe 'POST /ns-instances/scaling/' do
		context 'given an invalid content type' do
			let(:response) { post '/invalid_id/scale_in', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid NS instance' do
			let(:response) { post '/5825ce99c098a434c100000c/scale_in', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

	describe 'POST /ns-instances/scaling/' do
		context 'given an invalid content type' do
			let(:response) { post '/invalid_id/auto_scale', {parameter_id: "ap0"}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid NS instance' do
			let(:response) { post '/5825ce99c098a434c100000c/auto_scale', {parameter_id: "ap1"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid NS instance' do
			let(:response) { post '/5825ce99c098a434c100000c/auto_scale', {parameter_id: "ap1"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end
	end
end
