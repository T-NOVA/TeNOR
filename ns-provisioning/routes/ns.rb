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
# @see NsProvisioning
class Provisioner < NsProvisioning

  # @method get_ns_instances
  # @overload get "/ns-instances"
  # Gets all ns-instances
  get '/' do
    if params[:status]
      @nsInstances = Nsr.where(:status => params[:status])
    else
      @nsInstances = Nsr.all
    end

    return @nsInstances.to_json
  end

  # @method get_ns_instance_id
  # @overload get "/ns-instances/:id"
  # Get a ns-instance
  get '/:id' do
    begin
      @nsInstance = Nsr.find(params["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt(404)
    end
    return @nsInstance.to_json
  end

  # @method post_ns_instances
  # @overload post '/ns'
  # Instantiation request
  # @param [JSON]
  #Request body: {"nsd": "descriptor", "customer_id": "some_id", "nap_id": "some_id"}'
  post '/' do
c
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

    if settings.dependencies.all? { |x| @tenor_modules.detect { |el| el['name'] == x } }
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
        :notification => instantiation_info['callbackUrl'],
        :lifecycle_event_history => [],
        :audit_log => [],
        :marketplace_callback => instantiation_info['callbackUrl']
    }

    @instance = Nsr.new(instance)
    @instance.save!

    #call thread to process instantiation
    #EM.defer(instantiate(instantiation_info), callback())
    EM.defer do
      instantiate(@instance, nsd)
    end

    return 200, instance.to_json
  end

  # @method put_ns_instance_id
  # @overload put '/ns-instances/:ns_instance_id'
  # NS Instance update request
  # @param [JSON]
  put "/:ns_instance_id" do

  end

  # @method get_ns_instance_status
  # @overload gett '/ns-instances/:nsr_id/status'
  # Get instance status
  # @param [JSON]
  get "/:nsr_id/status" do

    begin
      instance = Nsr.find(params[:nsr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end

    return instance['status']
  end

  # @method put_ns_instance_status
  # @overload post '/ns-instances/:nsr_id/status'
  # Update instance status
  # @param [JSON]
  put "/:id/:status" do

    body, errors = parse_json(request.body.read)
    @instance = body['instance']
    popInfo = body['popInfo']

    begin
      @nsInstance = Nsr.find(params["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end

    if (popInfo.nil?)
      puts "Pop Info is null"
      @nsInstance.delete
      halt 200, "Removed correctly."
    end

    logger.debug @instance

    #popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    vnf_manager = @tenor_modules.select { |service| service["name"] == "vnf_manager" }[0]

    if params[:status] === 'terminate'

      #destroy vnf instances
      @instance['vnfrs'].each do |vnf|
        auth = {:auth => {:tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone]}}}
        begin
          response = RestClient.post vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VNF Manager unreachable'
        rescue RestClient::ResourceNotFound
          puts "Already removed from the VIM."
          logger.error "Already removed from the VIM."
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end

      end

      error = "Removing instance"
      #terminate VNF
      recoverState(popInfo, @instance['vnf_info'], @nsInstance, error)
      @nsInstance.delete
      halt 200, "Removed correctly"
    elsif params[:status] === 'start'

      @instance['vnfrs'].each do |vnf|
        puts vnf
        event = {:event => "start"}
        begin
          response = RestClient.put vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          logger.error "VNF Manager unreachable."
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        @nsInstance.push(lifecycle_event_history: "Executed a start")
      end

      @instance['status'] = params['status'].to_s.upcase
      @nsInstance.update_attributes(@instance)
    elsif params[:status] === 'stopped'

      @instance['vnfrs'].each do |vnf|
        logger.debug vnf
        event = {:event => "stop"}
        begin
          response = RestClient.put vnf_manager['host'].to_s + ":" + vnf_manager['port'].to_s + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
        rescue Errno::ECONNREFUSED
          logger.error "VNF Manager unreachable."
          halt 500, 'VNF Manager unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
      end

      @instance['status'] = params['status'].to_s.upcase
      @nsInstance
    end

    halt 200, "Updated correctly."

  end

  get "/ns-instances-mapping" do

  end

  post "/ns-instances-mapping" do

  end

  delete "/ns-instances-mapping/:id" do

  end

  # @method post_ns_instances_id_instantiate
  # @overload post '/ns-instances/:id/instantiate'
  # Response from VNF-Manager, send a message to marketplace
  post "/:nsr_id/instantiate" do
    logger.info "Instantiation response about " + params['nsr_id'].to_s
    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'
    # Validate JSON format
    response, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    callback_response = response['callback_response']
    @instance = response['instance']
    popInfo = response['popInfo']
    nsd = response['nsd']
    nsr_id = params['nsr_id']

    logger.debug "Callback response: " + callback_response.to_json
    logger.debug "Instance: " + @instance.to_json

    #vnf = {:vnf_id => vnf_id, :pop_id => pop_id}
    #extract vnfi_id from instantatieVNF response
    vnf_info = {}
    vnf_info[:vnfd_id] = callback_response['vnfd_id']
    vnf_info[:vnfi_id] = callback_response['vnfi_id']
    vnf_info[:vnfr_id] = callback_response['vnfr_id']
    #@instance['vnfis'] << vnf_info
    #@instance['vnfrs'] = []
    @instance['vnfrs'] << vnf_info

    begin
      instance = Nsr.find(@instance["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error e
      return 404
    end

    if callback_response['status'] == 'ERROR_CREATING'
      @instance['status'] = "ERROR_CREATING"
      instance.update_attributes(@instance)
      #recoverState(popInfo, @instance['vnf_info'], @instance, error)
      generateMarketplaceResponse(@instance['notification'], "Error creating VNF")
      return 200
    else
      @instance['status'] = "INSTANTIATED"
    end

    @instance['instantiation_end_time'] = DateTime.now.iso8601(3)
    instance.update_attributes(@instance)

    puts "Instantiation time: " + (DateTime.parse(@instance['instantiation_end_time']).to_time.to_f*1000 - DateTime.parse(@instance['created_at']).to_time.to_f*1000).to_s

    logger.debug @instance
    generateMarketplaceResponse(@instance['notification'], @instance)

    #insert statistic information to NS Manager
    EM.defer do
      begin
        response = RestClient.post settings.manager + '/performance-stats', @instance.to_json, :content_type => :json
      rescue => e
        logger.error e
      end
    end

    logger.debug "Sending start command"
    EM.defer do
      #send start command
      begin
        response = RestClient.put settings.manager + '/ns-instances/'+nsr_id+'/start', {}.to_json, :content_type => :json
      rescue Errno::ECONNREFUSED
        logger.error "Connection refused with the NS Manager"
          #halt 500, 'NS Manager unreachable'
      rescue => e
        logger.error e.response
        logger.error "Error with the start command"
        #halt e.response.code, e.response.body
      end
    end

    logger.debug "Starting monitoring workflow..."
    EM.defer do
      #start monitoring
      monitoringData(nsd, nsr_id, vnf_info)
    end

    return 200
  end

end
