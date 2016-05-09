#
# TeNOR - VNF Provisioning
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

RSpec.describe VNFMonitoring do
  def app
    VNFMonitoring
  end

  describe 'GET /vnf-monitoring/instances/:instance_id/monitoring-data/', type: :request do


    it 'queries FactoryGirl contributors on GitHub' do
      uri = URI('https://api.github.com/repos/thoughtbot/factory_girl/contributors')

      response = Net::HTTP.get(uri)
      puts response

      expect(response).to be_an_instance_of(String)
    end

    it "should redirect to dashboard" do
      #RestClient = double
      #response = double
      #response.stub(:code) { 200 }
      #RestClient.stub(:get) { response }

      file_response = File.new './spec/file_response.json'
     # a = stub_request(:get, "http://127.0.0.1/vnf-monitoring").to_return(:body => file_response, :status => 200)
#puts a
      puts "Before call"
      stub_request(:get, '/vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf').to_return(:body => file_response)
      stub_request(:get, "http://vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf").
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

     #response = get '/vnf-monitoring/instances/213123312/monitoring-data/?instance_type=vnf'
      RestClient.get("http://vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf")
      #RestClient.get("/vnf-monitoring/:vnfr_id/monitoring-parameters")
      puts "After call"
      #puts a
      #puts response.inspect
      #puts last_response
      puts "Done."


      #response = get '/vnf-monitoring/instances/ff7/monitoring-data/?instance_type=vnf'
      #puts last_response
#puts response
    end

    it "sould test something" do
      generateMetric("aa", 10)
      #create_monitoring_metric_object({})
    end

  end


end