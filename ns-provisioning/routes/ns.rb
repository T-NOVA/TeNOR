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

    logger.debug @instance

    popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

    if params[:status] === 'terminate'

      #destroy vnf instances
      @instance['vnfrs'].each do |vnf|
        auth = {:auth => { :tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone] } } }
        begin
          response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          #halt e.response.code, e.response.body
        end

      end

      #terminate VNF
      recoverState(popInfo, @instance['vnf_info'], @instance, error)
      #removeInstance(@instance)
    elsif params[:status] === 'stopped'

      @instance['vnfrs'].each do |vnf|
        puts vnf
        event = {:event => "stop"}
        begin
          response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
      end

      @instance['status'] = params['status'].to_s
      @instance = updateInstance(@instance)

      #terminate VNF
      #halt 400, "Not implemented yet."
      #change status
    end

    halt 200, "Updated correctly."

  end

  delete "/ns-instances/:ns_instance_id" do
    begin
      response = RestClient.get settings.ns_instance_repository + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "This instance id no exists"
    end
    @instance, errors = parse_json(response)
    logger.debug @instance

    popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

    #destroy vnf instances
    @instance['vnfrs'].each do |vnf|

      if (!vnf['vnfr_id'].nil?)
        auth = {:auth => {:tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone]}}}
        begin
          response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          puts "Delete method."
          #halt e.response.code, e.response.body
        end
      end

    end

    #terminate VNF
    recoverState(popInfo, @instance['vnf_info'], @instance, "Removing instance.")

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
    vnf_info[:vnfi_id] = callback_response['vnfi_id']
    vnf_info[:vnfr_id] = callback_response['vnfr_id']
    #@instance['vnfis'] << vnf_info
    @instance['vnfrs'] = []
    @instance['vnfrs'] << vnf_info

    @instance['status'] = "INSTANTIATED"
    @instance['instantiation_end_time'] = Time.now

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
    wicm_data = {:nsd_id => nsd['id'], :customer_id => instantiation_info['customer_id'], :nap_id => instantiation_info['nap_id'], pop_id => popInfo['popId']}
    #"/vnf-connectivity"
    @instance = updateInstance(@instance)
  end
end
