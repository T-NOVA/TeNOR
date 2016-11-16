require_relative 'spec_helper'

RSpec.describe NSMonitoring do
    before do
        begin
        # DatabaseCleaner.start
        ensure
        # DatabaseCleaner.clean
        end
    end

    let(:app) do
        Rack::Builder.new do
            eval File.read('config.ru')
        end
    end

    describe 'POST /ns-monitoring/monitoring-parameters' do
        context 'given an invalid content type' do
            let(:response) { post '/ns-monitoring/monitoring-parameters', File.read(File.expand_path('../fixtures/monitoring_request.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' } }

            it 'responds with a 415' do
                expect(response.status).to eq 415
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end

        context 'given a valid Monitoring' do
            let(:response) { post '/ns-monitoring/monitoring-parameters', File.read(File.expand_path('../fixtures/monitoring_request.json', __FILE__)), rack_env = { 'CONTENT_TYPE' => 'application/json' } }

            it 'responds with a 200' do
                expect(response.status).to eq 200
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end
    end

    describe 'POST /ns-monitoring/monitoring-parameters' do
        context 'given an invalid content type' do
            val = {"instance_id": "vnfr_id","vdu_id": "uuid","type": "cpu_util","value": "10","unit": "%","timestamp": Time.parse("1970-01-01T00:00:00Z").to_i}
            let(:response) { post '/ns-monitoring/vnf-instance-readings/vnfr_id', val.to_json, rack_env = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' } }

            it 'responds with a 415' do
                expect(response.status).to eq 415
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end

        context 'given a valid Monitoring' do
            val = {"instance_id": "vnfr_id","vdu_id": "uuid","type": "cpu_util","value": "10","unit": "%","timestamp": Time.parse("1970-01-01T00:00:00Z").to_i}
            let(:response) { post '/ns-monitoring/vnf-instance-readings/vnfr_id', val.to_json, rack_env = { 'CONTENT_TYPE' => 'application/json' } }

            it 'responds with a 200' do
                expect(response.status).to eq 200
            end

            it 'responds with an empty body' do
                expect(response.body).to be_empty
            end
        end
    end
end
