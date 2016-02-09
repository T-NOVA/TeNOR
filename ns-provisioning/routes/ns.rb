#
# TeNOR - NS Provisioning
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
# @see OrchestratorNsProvisioner
class OrchestratorNsProvisioner < Sinatra::Application

  before do
    if request.path_info == '/gk_credentials'
      return
    end

    if settings.environment == 'development'
      return
    end

    authorized?

  end

  # @method post_ns
  # @overload post '/ns'
  #   Post a NS in JSON format
  #   @param [JSON]
  # Post a NS
  #Request body: {"nsd": "descriptor", "customer_id": "some_id", "nap_id": "some_id"}'
  post '/ns-instances' do

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'
    # Validate JSON format
    instantiation_info, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    #call thread to process instantiation
    EM.defer do
      instantiate(instantiation_info)
    end

    return 200
  end


  #update instance
  put "/ns-instances/:ns_instance_id" do

  end

  #get instance status
  get "/ns-instances/:ns_instance_id/status" do
    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    instance, errors = parse_json(response)
    return instance['status']
  end

  #get instances given status
  get "/ns-instances" do
    if params[:status]
      url = settings.ns_instance_repository + '/ns-instances?status=' + params[:status]
    else
      url = settings.ns_instance_repository + '/ns-instances'
    end

    begin
      response = RestClient.get url, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    return response
  end

  #update instance status
  put "/ns-instances/:ns_instance_id/:status" do
    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 400, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    @instance, errors = parse_json(response)
    #@instance['status'] = params['status'].to_s
    #@instance = updateInstance(@instance)

    logger.debug @instance

    @instance['vnfs'].each do |vnf|
      puts vnf
      #get vnf keystoneUrl
      event = { :event => "stop" }
      begin
        response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/:vnfr_id/config', event.to_json, :content_type => :json
      rescue => e
        logger.error e
        if (defined?(e.response)).nil?
          halt 400, "NS-Instance Repository unavailable"
        end
        halt e.response.code, e.response.body
      end

    end

    if params[:status] === 'terminate'
      #remove openstack data
      keystoneUrl = ""
      neutronUrl = ""
      popInfo = getPopInfo(vnf['pop_id'])
      #VIM authentication
      extra_info = popInfo['info'][0]['extrainfo'].split(" ")
      for item in extra_info
        key = item.split('=')[0]
        if key == 'keystone-endpoint'
          keystoneUrl = item.split('=')[1]
        elsif key == 'neutron-endpoint'
          neutronUrl = item.split('=')[1]
        end
      end

      #terminate VNF
      token = openstackAuthentication(keystoneUrl, popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
      deleteRouter(neutronUrl, vnf['router_id'], token)
      deleteUser(keystoneUrl, vnf['user_id'], token)
      deleteProject(keystoneUrl, vnf['tenant_id'], token)

      recoverState(keystoneUrl, neutronUrl, vnf_info, @instance, error, token)

      removeInstance(@instance)

    elsif params[:status] === 'stopped'
      #terminate VNF
      #halt 400, "Not implemented yet."
      #change status
    end

  end

  delete "/ns-instances/:ns_instance_id" do
    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "THis instance id no exists"
    end
    @instance, errors = parse_json(response)
    logger.debug @instance

    #call VNFManger

    keystoneUrl = ""
    neutronUrl = ""


    popInfo = getPopInfo(vnf['pop_id'])
    #VIM authentication
    extra_info = popInfo['info'][0]['extrainfo'].split(" ")
    for item in extra_info
      key = item.split('=')[0]
      if key == 'keystone-endpoint'
        keystoneUrl = item.split('=')[1]
      elsif key == 'neutron-endpoint'
        neutronUrl = item.split('=')[1]
      end
    end

    #remove openstack data
    @instance['vnfs'].each do |vnf|
      puts vnf

      token = openstackAuthentication(keystoneUrl, popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
      deleteRouter(neutronUrl, vnf['router_id'], token)
      deleteUser(keystoneUrl, vnf['user_id'], token)
      deleteProject(keystoneUrl, vnf['tenant_id'], token)

      #delete monitoring data

      #delete monitoring data repository

    end

    #remove instance_id from repository
    removeInstance(params['ns_instance_id'])

    halt 200, "Instance removed correctly"
  end

  get "/ns-instances-mapping" do

  end

  post "/ns-instances-mapping" do

  end

  delete "/ns-instances-mapping/:id" do

  end

  # @method post_ns-instances
  # @overload post '/ns-instances/:id/instantiate'
  # Response from VNF-Manager, send a message to marketplace
  #/ns-instances/:ns_instance_id/instantiate
  post "/ns-instances/:id/instantiate" do
    logger.debug "Response about " + params['id']
    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'
    # Validate JSON format
    callback_response, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    logger.debug callback_response
    puts callback_response.to_json

    #find instance id, update data
    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + params['id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 400, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    @instance, errors = parse_json(response)

    #vnf = {:vnf_id => vnf_id, :pop_id => pop_id}
    #extract vnfi_id from instantatieVNF response
    vnf_info = {}
    vnf_info[:vnfd_id] = callback_response['vnfd_id']
    vnf_info[:vnfi_id]= callback_response['vnfi_id']
    #@instance['vnfis'] << vnf_info
    @instance['vnfs'] = []
    @instance['vnfs'] << vnf_info

    @instance['status'] = "INSTANTIATED"

    logger.debug @instance
    @instance = updateInstance(@instance)

    generateMarketplaceResponse(@instance['marketplace_callback'], @instance)

    #get NSD
    begin
      response = RestClient.get settings.ns_catalogue + '/network-services/' + @instance['nsd_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 400, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    nsd, errors = parse_json(response)

    #start monitoring
    monitoringData(nsd, params['id'])

    #if done, send mapping information to marketplace
    logger.debug @instance['marketplace_callback']
    #generateMarketplaceResponse(@instance['marketplace_callback'], @instance)

    return 200

    logger.debug "Call WICM"
    #customer ID, location ID (NAP), service descriptor and NFVI-PoP ID
    wicm_data =  {:nsd_id => nsd['id'], :customer_id => instantiation_info['customer_id'], :nap_id => instantiation_info['nap_id'], pop_id => popInfo['popId']}
    #"/vnf-connectivity"
    @instance = updateInstance(@instance)
  end
end
