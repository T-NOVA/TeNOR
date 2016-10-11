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
# @see ServiceConfigurationHelper
module ServiceConfigurationHelper

  def registerService(json)
    @json = JSON.parse(json)
    @json[:type] = "internal"

    AuthenticationHelper.loginGK()
    gkServices = AuthenticationHelper.getGKServices()

    index = 0
    while index < gkServices['shortname'].length do
      if gkServices['shortname'][index] == @json['name']
        begin
          @service = ServiceModel.find_by(:name => @json['name'])
          @json['service_key'] = gkServices['service-key'][index]
          serviceUri = @json['host'] + ":" + @json['port'].to_s
          AuthenticationHelper.sendServiceAuth(serviceUri, gkServices['service-key'][index])
          @service.update_attributes(@json)
          return "Service updated"
        rescue Mongoid::Errors::DocumentNotFound => e
          @json['service_key'] = gkServices['service-key'][index]
          @service = ServiceModel.create!(@json)
          serviceUri = @json['host'] + ":" + @json['port'].to_s
          AuthenticationHelper.sendServiceAuth(serviceUri, gkServices['service-key'][index])
          return "Service registered"
        end
      end
      index +=1
    end

    if index === gkServices['shortname'].length
      begin
        @service = ServiceModel.find_by(:name => @json['name'])
        key = registerServiceinGK(@json['name'])
        metadata = JSON.parse(key)
        @json['service_key'] = gkServices['service-key'][index]
        access = @json['host'] + ":" + @json['port'].to_s
        AuthenticationHelper.sendServiceAuth(access, metadata["info"][0]["service-key"])
        @service.update_attributes(@json)
        return "Service updated"
      rescue Mongoid::Errors::DocumentNotFound => e
        begin
          key = registerServiceinGK(@json['name'])
          metadata = JSON.parse(key)
          @json['service_key'] = gkServices['service-key'][index]
          access = @json['host'] + ":" + @json['port'].to_s
          AuthenticationHelper.sendServiceAuth(access, metadata["info"][0]["service-key"])
          @service = ServiceModel.create!(@json)
          return "Service registered"
        rescue => e
          logger.error e
          halt 500, {'Content-Type' => 'text/plain'}, "Error registering the service"
        end
      end
    end
  end

  def registerExternalService()
    @json = JSON.parse(json)
    @json[:type] = "external"
    begin
      @service = ServiceModel.find_by(:name => @json['name'])
      @service.update_attributes(@json)
      return "Service updated"
    rescue Mongoid::Errors::DocumentNotFound => e
      begin
        @service = ServiceModel.create!(@json)
        return "Service registered"
      rescue => e
        logger.error e
        halt 500, {'Content-Type' => 'text/plain'}, "Error registering the service"
      end
    end
  end

  def unregisterService(name)
    settings.services[name] = nil
    ServiceModel.find_by(name: params["microservice"]).delete
  end

  def updateService(service)
    @service = ServiceModel.find_by(name: params["name"])
    @service.update_attributes(@json)
  end

  # Unregister all the services
  def unRegisterAllService
    ServiceModel.delete_all
  end

  # Check if the token of service is correct
  def auth(key)
    #TODO
    #return response
    status 201
  end

  def self.getServices()
    begin
      @services = ServiceModel.all
    rescue => e
      puts e
    end
    return @services
  end

  def self.getService(name)
    begin
      @service = ServiceModel.find_by(:name => name)
    rescue => e
      puts e
    end
    return @service
  end

  def self.publishServices
    services = getServices()
    services.each do |service|
      logger.debug "Sending dependencies to " + service['name']
      if service['type'] == "internal"
        begin
          RestClient.post service['host'] + ":" + service['port'] + "/gk_dependencies", services.to_json, :content_type => :json
        rescue => e
          #logger.error e
          #puts e
          #halt 500, {'Content-Type' => 'text/plain'}, "Error sending dependencies to " +service['name']
        end
      end
    end
  end

  def self.publishService(name)
    services = getServices
    service = getService(name)
    begin
      RestClient.post service['host'] + ":" + service['port'] + "/gk_dependencies", services.to_json, :content_type => :json
    rescue => e
      #logger.error e
      puts e
      #halt 500, {'Content-Type' => 'text/plain'}, "Error sending dependencies to " +service['name']
    end

  end

  # Method which lists all available interfaces
  #
  # @return [Array] the array containing a list of all interfaces
  def interfaces_list
    [
        {
            'uri' => '/',
            'method' => 'GET',
            'purpose' => 'REST API Structure and Capability Discovery'
        },
        {
            'uri' => '/network-services',
            'method' => 'GET',
            'purpose' => 'Get list of Network Services'
        },
        {
            'uri' => '/network-services/{id}',
            'method' => 'GET',
            'purpose' => 'Get a Network Service'
        },
        {
            'uri' => '/network-services',
            'method' => 'POST',
            'purpose' => 'Create a new Network Service'
        },
        {
            'uri' => '/network-services/{id}',
            'method' => 'PUT',
            'purpose' => 'Update a new Network Service'
        },
        {
            'uri' => '/network-services/{id}',
            'method' => 'DELETE',
            'purpose' => 'Delete a new Network Service'
        },
        {
            'uri' => '/vnfs',
            'method' => 'GET',
            'purpose' => 'Get list of VNFs'
        },
        {
            'uri' => '/vnfs',
            'method' => 'POST',
            'purpose' => 'Create a new VNFs'
        },
        {
            'uri' => '/vnfs/{id}',
            'method' => 'PUT',
            'purpose' => 'Update a VNF'
        },
        {
            'uri' => '/ns-instances',
            'method' => 'POST',
            'purpose' => 'Create an instance request'
        },
        {
            'uri' => '/ns-instances',
            'method' => 'GET',
            'purpose' => 'Get list of instances'
        },
        {
            'uri' => '/configs/registerService',
            'method' => 'POST',
            'purpose' => 'Register a service configuration'
        },
        {
            'uri' => '/configs/unRegisterService/{microservice}',
            'method' => 'POST',
            'purpose' => 'Unregister a service configuration'
        },
        {
            'uri' => '/configs/services',
            'method' => 'GET',
            'purpose' => 'List all services configuration'
        },
        {
            'uri' => '/configs/services',
            'method' => 'PUT',
            'purpose' => 'Update service configuration'
        },
        {
            'uri' => '/configs/services/{name}/status',
            'method' => 'PUT',
            'purpose' => 'Update service status'
        },
    ]
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= TnovaManager.logger
  end
end
