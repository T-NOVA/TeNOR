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

    # Return if content-type is invalid
    return 415 unless request.content_type == 'application/json'
    # Validate JSON format
    instantiation_info, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    nsd = instantiation_info['nsd']

    if instantiation_info['flavour'].nil?
      error = "Flavour is null"
      halt 400, "Failed creating instance. Flavour is null"
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
        :lifecycle_event_history => ['INIT'],
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
    #popInfo = body['popInfo']

    begin
      @nsInstance = Nsr.find(params["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end

    #if (popInfo.nil?)
    #      puts "Pop Info is null"
    #      @nsInstance.delete
    #      halt 200, "Removed correctly."
    #    end

    #popInfo = getPopInfo(@instance['vnf_info']['pop_id'])
    #popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

    if params[:status] === 'terminate'
      logger.info "Starting thread for removing VNF and NS instances."
#      EM.defer do
      operation = proc {
        @nsInstance['vnfrs'].each do |vnf|
          logger.info "Terminate VNF " + vnf['vnfr_id'].to_s
          puts vnf

          puts "Pop_id: " + vnf['pop_id'].to_s
          if vnf['pop_id'].nil?
            raise "VNF not defined"
          end

          popInfo = getPopInfo(vnf['pop_id'])
          if popInfo == 400
            logger.error "Pop id no exists."
            return
            raise "Pop id no exists."
          end
#          popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

          pop_auth = @nsInstance['authentication'].find { |pop| pop['pop_id'] == vnf['pop_id'] }
          popUrls = pop_auth['urls']


          if !vnf['vnfr_id'].nil?
            #auth = {:auth => {:tenant => @instance['vnf_info']['tenant_name'], :username => @instance['vnf_info']['username'], :password => @instance['vnf_info']['password'], :url => {:keystone => popUrls[:keystone]}}}
            auth = {:auth => {:tenant => pop_auth['tenant_name'], :username => pop_auth['username'], :password => pop_auth['password'], :url => {:keystone => popUrls[:keystone]}}}
            begin
              response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, :content_type => :json
            rescue Errno::ECONNREFUSED
              #halt 500, 'VNF Manager unreachable'
            rescue RestClient::ResourceNotFound
              puts "Already removed from the VIM."
              logger.error "Already removed from the VIM."
            rescue => e
              puts "Probably and error with mAPI"
              puts e
              logger.error e.response
              #halt e.response.code, e.response.body
            end
          end
        end

        logger.info "VNFs removed correctly."
        error = "Removing instance"
        recoverState(@nsInstance, error)
        logger.info "NSr removed."
        #notify marketplace for correct removal?
        #return 200, "Removed correctly"
      }
      errback = proc {
        logger.error "Error with the removing process..."
      }
      callback = proc {
        logger.info "Removing finished correctly."
      }
      EventMachine.defer(operation, callback, errback)

#      end
    elsif params[:status] === 'start'
      @instance['vnfrs'].each do |vnf|
        logger.info "Starting VNF " +vnf['vnfr_id'].to_s
        event = {:event => "start"}
        begin
          response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
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
    elsif params[:status] === 'stop'
      @instance['vnfrs'].each do |vnf|
        logger.debug vnf
        event = {:event => "stop"}
        begin
          response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, :content_type => :json
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
    begin
      instance = Nsr.find(@instance["id"])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error e
      return 404
    end
    #popInfo = response['popInfo']
    nsd = response['nsd']
    nsr_id = params['nsr_id']

    #logger.debug "Callback response: " + callback_response.to_json
    #logger.info "Instance: " + @instance.to_json

    if callback_response['status'] == 'ERROR_CREATING'
      @instance['status'] = "ERROR_CREATING"
      @instance['lifecycle_event_history'].push("ERROR_CREATING")
      instance.update_attributes(@instance)
      generateMarketplaceResponse(@instance['notification'], "Error creating VNF")
      return 200
    end

    @instance['lifecycle_event_history'].push("VNF " + callback_response['vnfd_id'].to_s + " INSTANTIATED")
    @vnfr = @instance['vnfrs'].find { |vnf_info| vnf_info['vnfd_id'] == callback_response['vnfd_id'] }
    @vnfr['vnfi_id'] = callback_response['vnfi_id']
    @vnfr['status'] = "INSTANTIATED"
    @vnfr['vnf_addresses'] = callback_response['vnf_addresses']

    instance.update_attributes(@instance)

    #for each VNF instantiated, read the connection point in the NSD and extract the resource id
    EM.defer do

      logger.error 'VNFR Stack Resources: ' + callback_response['stack_resources'].to_s
      vnfr = callback_response['stack_resources']
      nsd['vld']['virtual_links'].each do |vl|
        vl['connections'].each do |conn|
          vnf_net = conn.split("#")[1]
          vnf_id = vnf_net.split(":")[0]
          net = vnf_net.split(":ext_")[1]

          if (vnf_id == vnfr['vnfd_reference'])
            vlr = vnfr['vlr_instances'].find { |vlr| vlr['alias'] == net }
            vnf_ports = vnfr['port_instances'].find_all { |port| port['vlink_ref'] == vlr['id'] }
            ports = {}
            ports['ns_network'] = conn
            ports['vnf_ports'] = vnf_ports
            @instance['resource_reservation'][:ports] << ports
            instance.update_attributes(@instance)
          end
        end
      end
    end

    logger.info "Checking if all the VNFs are instantiated."
    nsd['vnfds'].each do |vnf|
      vnf_instance = @instance['vnfrs'].find { |vnf_info| vnf_info['vnfd_id'] == vnf }
      if vnf_instance['status'] != "INSTANTIATED"
        logger.info "VNF " + vnf.to_s + " is not ready."
        logger.info vnf_instance['status']
        return
      end
    end

    logger.info "Service is ready. All VNFs are instantiated"
    @instance['status'] = "INSTANTIATED"
    @instance['lifecycle_event_history'].push("INSTANTIATED")
    @instance['instantiation_end_time'] = DateTime.now.iso8601(3)
    instance.update_attributes(@instance)

    logger.info "Instantiation time: " + (DateTime.parse(@instance['instantiation_end_time']).to_time.to_f*1000 - DateTime.parse(@instance['created_at']).to_time.to_f*1000).to_s
    generateMarketplaceResponse(@instance['notification'], @instance)
    logger.info "Marketplace is notified"

    logger.info "Sending statistic information to NS Manager"
    EM.defer do
      begin
        response = RestClient.post settings.manager + '/performance-stats', @instance.to_json, :content_type => :json
      rescue => e
        logger.error e
      end
    end

    logger.info "Sending start command"
    EM.defer do
      sleep(5)
      begin
        response = RestClient.put settings.manager + '/ns-instances/' + nsr_id + '/start', {}.to_json, :content_type => :json
      rescue Errno::ECONNREFUSED
        logger.error "Connection refused with the NS Manager"
      rescue => e
        logger.error e.response
        logger.error "Error with the start command"
      end
    end

    logger.info "Starting monitoring workflow..."
    EM.defer do
      monitoringData(nsd, nsr_id, @instance)
    end

    return 200
  end

end
