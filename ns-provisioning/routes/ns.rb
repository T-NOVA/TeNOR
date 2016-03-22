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

    nsd = instantiation_info['nsd']

    if instantiation_info['flavour'].nil?
      error = "Flavour is null"
      halt 400, "Failed creating instance. Flavour is null"
      #generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
    end

    if settings.dependencies.all? { |x| @tenor_modules.detect{|el| el['name'] == x} }
      halt 400, "The orchestrator has not the correct dependencies"
    end

    instance = {
            :nsd_id => nsd['id'],
            :descriptor_reference => nsd['id'],
            :auto_scale_policy => nsd['auto_scale_policy'],
            :connection_points => nsd['connection_points'],
            :monitoring_parameters => nsd['monitoring_parameters'],
            :service_deployment_flavour => instantiation_info['flavour'],
            :vendor => nsd['vendor'],
            :version => nsd['version'],
            #vlr
            :vnfrs => [],
            :lifecycle_events => nsd['lifecycle_events'],
            :vnf_depedency => nsd['vnf_depedency'],
            :vnffgd => nsd['vnffgd'],
            #pnfr
            :resource_reservation => [],
            :runtime_policy_info => [],
            :status => "INIT",
            :notification => "",
            :lifecycle_event_history => [],
            :audit_log => [],
            :marketplace_callback => instantiation_info['callbackUrl']
        }

    begin
      @instance = createInstance(instance)
    rescue => e
      halt 400, "Failed creating instance. Instance repository fails creating the instance"
    end

    #call thread to process instantiation
    #EM.defer(instantiate(instantiation_info), callback())
    EM.defer do
      instantiate(@instance, nsd)
    end

    return 200, instance.to_json
  end

  def callback()
    puts "callback"
    return "ERROR CALLBACK"
  end

  #update instance
  put "/ns-instances/:ns_instance_id" do

  end

  #get instance status
  get "/ns-instances/:ns_instance_id/status" do
    url = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]
    begin
      response = RestClient.get url['host'].to_s + ":" + url['port'].to_s + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
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
    url = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]
    if params[:status]
      url = url['host'].to_s + ":" + url['port'].to_s + '/ns-instances?status=' + params[:status]
    else
      url = url['host'].to_s + ":" + url['port'].to_s + '/ns-instances'
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

  get "/ns-instances/:instance" do
    url = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]
    begin
      response = RestClient.get url['host'].to_s + ":" + url['port'].to_s  + '/ns-instances/'+params['instance'], :content_type => :json
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

    body, errors = parse_json(request.body.read)
    @instance = body['instance']
    popInfo = body['popInfo']

    if(popInfo.nil?)
      puts "Pop Info is null"
      removeInstance(@instance)
      halt 200, "Removed correctly."
    end

    logger.debug @instance

    #popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    vnf_manager = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]

    if params[:status] === 'terminate'

      #destroy vnf instances
      @instance['vnfrs'].each do |vnf|
        auth = {:auth => { :tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone] } } }
        begin
          response = RestClient.post vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s  + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue RestClient::ResourceNotFound
          puts "Already removed from the VIM."
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end

      end

      error = "Removing instance"
      #terminate VNF
      recoverState(popInfo, @instance['vnf_info'], @instance, error)
      EM.defer do
        removeInstance(@instance)
      end
      halt 200, "Removed correctly"
    elsif params[:status] === 'start'

      @instance['vnfrs'].each do |vnf|
        puts vnf
        event = {:event => "start"}
        begin
          response = RestClient.put vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s  + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
      end

      @instance['status'] = params['status'].to_s.upcase
      updateInstance(@instance)
    elsif params[:status] === 'stopped'

      @instance['vnfrs'].each do |vnf|
        puts vnf
        event = {:event => "stop"}
        begin
          response = RestClient.put vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s  + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
      end

      @instance['status'] = params['status'].to_s.upcase
      updateInstance(@instance)
    end

    halt 200, "Updated correctly."

  end

  #remove
  delete "/ns-instances/:ns_instance_id" do
    url = @tenor_modules.select {|service| service["name"] == "ns_instance_repository" }[0]
    vnf_manager = @tenor_modules.select {|service| service["name"] == "vnf_manager" }[0]
    wicm = @tenor_modules.select {|service| service["name"] == "wicm" }[0]
    begin
      response = RestClient.get url['host'].to_s + ":" + url['port'].to_s + '/ns-instances/' + params['ns_instance_id'].to_s, :content_type => :json
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error "This instance id no exists"
    end
    @instance, errors = parse_json(response)
    logger.debug @instance

    # Request WICM to stop redirecting traffic
    begin
      response = RestClient.delete wicm['host'].to_s + ":" + wicm['port'].to_s + "/vnf-connectivity/#{@instance['nsd_id']}", :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'WICM unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    begin
      popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
      popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    rescue
      removeInstance(@instance['id'])
      halt 200, "Instance removed correctly"
    end

    #destroy vnf instances
    @instance['vnfrs'].each do |vnf|

      if (!vnf['vnfr_id'].nil?)
        auth = {:auth => {:tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone]}}}
        begin
          response = RestClient.post vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          puts "Delete method."
          halt e.response.code, e.response.body
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
  post "/ns-instances/:nsr_id/instantiate" do
    logger.debug "Response about " + params['nsr_id'].to_s
    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'
    # Validate JSON format
    response, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    callback_response = response['callback_response']
    @instance = response['instance']
    popInfo = response['popInfo']
    nsr_id = params['nsr_id']

    puts callback_response.to_json
    puts @instance.to_json

    #vnf = {:vnf_id => vnf_id, :pop_id => pop_id}
    #extract vnfi_id from instantatieVNF response
    vnf_info = {}
    vnf_info[:vnfd_id] = callback_response['vnfd_id']
    vnf_info[:vnfi_id] = callback_response['vnfi_id']
    vnf_info[:vnfr_id] = callback_response['vnfr_id']
    #@instance['vnfis'] << vnf_info
    #@instance['vnfrs'] = []
    @instance['vnfrs'] << vnf_info

    if callback_response['status'] == 'ERROR_CREATING'
      @instance['status'] = "ERROR_CREATING"
      updateInstance(@instance)
      #recoverState(popInfo, @instance['vnf_info'], @instance, error)
      generateMarketplaceResponse(@instance['marketplace_callback'], "Error creating VNF")
      return 200
    else
      @instance['status'] = "INSTANTIATED"
    end

    @instance['instantiation_end_time'] = DateTime.now.iso8601(3)
    updateInstance(@instance)

    puts "Instantiation time: " + (DateTime.parse(@instance['instantiation_end_time']).to_time.to_f*1000 - DateTime.parse(@instance['created_at']).to_time.to_f*1000).to_s

    logger.debug @instance
    generateMarketplaceResponse(@instance['marketplace_callback'], @instance)

    #insert statistic information to NS Manager
    EM.defer do
      begin
        response = RestClient.post settings.manager + '/performance-stats', @instance.to_json, :content_type => :json
      rescue => e
        logger.error e
      end
    end

    #get NSD, for monitoring parameters
    ns_catalogue = @tenor_modules.select {|service| service["name"] == "ns_catalogue" }[0]
    begin
      response = RestClient.get ns_catalogue['host'].to_s + ":" + ns_catalogue['port'].to_s  + '/network-services/' + @instance['nsd_id'].to_s, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 400, "NS-Instance Repository unavailable"
      end
      halt e.response.code, e.response.body
    end
    nsd, errors = parse_json(response)

    #start monitoring
    EM.defer do
      monitoringData(nsd, nsr_id, vnf_info)
    end

    #if done, send mapping information to marketplace
    logger.debug @instance['marketplace_callback']
    #generateMarketplaceResponse(@instance['marketplace_callback'], @instance)

    return 200
  end
end
