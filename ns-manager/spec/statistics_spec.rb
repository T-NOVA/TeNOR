require_relative 'spec_helper'

RSpec.describe TnovaManager do
	def app
		Statistics
  end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
	end

	describe 'POST /generic' do
		context 'given a valid Metric' do
			let(:response) { post '/generic/metric', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

	describe 'GET /generic' do
		context 'when there are no statistics' do
			let(:response) { get '/generic' }

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
			before { create_pair(:statisticModel) }
			let(:response) { get '/generic' }

			it 'does not return an empty body' do
				expect(JSON.parse response.body).to_not be_empty
			end

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'each array item should be a Hash' do
				expect(JSON.parse response.body).to all be_a Hash
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end

	describe 'POST /performance_stats' do
		context 'given an invalid Metrics' do
			let(:response) { post '/performance_stats', {instance_id: "id"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 400' do
				expect(response.status).to eq 400
      end

			it 'response should be empty' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid Metric' do
			let(:response) { post '/performance_stats', {instance_id: "id", created_at: "2016-11-24T14:55:20.420+00:00", mapping_time: "2016-11-24T14:55:20.420+00:00", instantiation_start_time: "2016-11-24T14:55:20.420+00:00", instantiation_end_time: "2016-11-24T14:55:20.420+00:00"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

	describe 'GET /performance_stats' do
		context 'when the Statistic is found' do
			before { create_pair(:performanceStatisticModel) }
      let(:response_found) { get '/performance_stats' }

			it 'response body should not be empty' do
				expect(JSON response_found.body).to_not be_empty
			end

			it 'response body should contain a Array' do
				expect(JSON.parse response_found.body).to be_an Array
			end

			it 'responds with a 200' do
				expect(response_found.status).to eq 200
			end
		end
	end
end
