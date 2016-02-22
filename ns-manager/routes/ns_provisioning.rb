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
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
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
    logger.error "Instantiation correct."
    logger.error response.code

    updateStatistics('ns_instantiated_requests')

    return response.code, response.body
  end

  put '/ns-instances/:ns_instance_id' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
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
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
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
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
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
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['ns_instance_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    @ns_instance, error = parse_json(response)

    #call popInfo Function
    getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    info = { :instance => @ns_instance, :popInfo => popInfo }

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath, info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
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
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['ns_instance_id'], 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    @ns_instance, error = parse_json(response)

    #call popInfo Function
    popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    info = { :instance => @ns_instance, :popInfo => popInfo }

    begin
      response = RestClient.put @service.host + ":" + @service.port.to_s + request.fullpath.to_s + '/terminate', info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    updateStatistics('ns_terminated_requests')

    return response.code, response.body
  end

  post '/ns-instances/:ns_instance_id/instantiate' do
    begin
      @service = ServiceModel.find_by(name: "nsprovisioning")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
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

  get '/vnf-provisioning/vnf-instances' do
    begin
      @service = ServiceModel.find_by(name: "vnfmanager")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "VNF Manager not registred."
    end

    begin
      response = RestClient.get @service.host + ":" + @service.port.to_s + request.fullpath, 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Manager unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    return response.code, response.body

  end

end