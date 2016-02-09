#
# TeNOR - NS Manager
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
# @see TnovaManager
class TnovaManager < Sinatra::Application

  post '/ns-instances' do

    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get VNF by id
    begin
      nsd = RestClient.get settings.ns_catalogue + '/network-services/' + instantiation_info['ns_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    provisioning = {:nsd => JSON.parse(nsd), :customer_id => "some_id", :nap_id => "some_id", :callbackUrl => instantiation_info['callbackUrl'], :flavour => instantiation_info['flavour']}

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, provisioning.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_instantiated_requests')

    return response.code, response.body
  end

  put '/ns-instances/:ns_instance_id' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_updated_requests')
    updateStatistics('ns_terminated_requests')

    return response.code, response.body
  end

  get "/ns-instances/:ns_instance_id/status" do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  get "/ns-instances" do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  put '/ns-instances/:ns_instance_id/:status' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  delete '/ns-instances/:ns_instance_id' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.delete @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

  post '/ns-instances/:ns_instance_id/instantiate' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body
  end

end