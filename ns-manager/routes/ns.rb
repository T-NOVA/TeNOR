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

  get '/vnfs' do
    begin
      @service = ServiceModel.find_by(name: "vnfmanager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  get '/vnfs/:vnf_id' do
    begin
      @service = ServiceModel.find_by(name: "vnfmanager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  post '/vnfs' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "vnfmanager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.post  @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    #updateStatistics('vnfs_created_requests')
    return response.code, response.body

  end

  put '/vnfs/:external_vnf_id' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "vnfmanager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put  @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  get '/network-services' do

    begin
      @service = ServiceModel.find_by(name: "nscatalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  get '/network-services/:id' do

    begin
      @service = ServiceModel.find_by(name: "nscatalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.get  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  post '/network-services' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "nscatalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.post  @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_created_requests')

    return response.code, response.body

  end

  put '/network-services/:external_ns_id' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'

    begin
      @service = ServiceModel.find_by(name: "nscatalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.put  @service.host + ":" + @service.port.to_s + request.fullpath, request.body.read, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

  delete '/network-services/:external_ns_id' do

    begin
      @service = ServiceModel.find_by(name: "nscatalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "Microservice unrechable."
    end

    begin
      response = RestClient.delete  @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end