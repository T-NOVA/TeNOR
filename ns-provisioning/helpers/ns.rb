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
# @see NsProvisioner
module NsProvisioner

  # Sends a notification to the callback url
  #
  # @param [JSON] message Notification URL
  # @param [JSON] message the message to send
  def generateMarketplaceResponse(notification_url, message)
    logger.debug "Notification url: " + notification_url
    logger.debug message.to_json
    begin
      response = RestClient.post notification_url, message.to_json, :content_type => :json
    rescue RestClient::ResourceNotFound
      logger.error "Error sending the callback to the marketplace."
      puts "No exists in the Marketplace."
    rescue => e
      logger.error e
      #halt e.response.code, e.response.body
    end
  end

  # Generates a standard Hash for errors.
  #
  # @param [JSON] message NSr id
  # @param [JSON] message Status
  # @param [JSON] message Message
  # @return [Hash] The error message
  def generateError(ns_id, status, message)
    message = {
        :nsd_id => ns_id,
        :status => status,
        :cause => message
    }
    return message
  end

  # Recover the state due to fail during the instatiation or when the instance should be removed
  #
  # @param [JSON] message NSr
  # @return [Hash, nil] NS
  # @return [Hash, String] if the parsed message is an invalid JSON
  #def recoverState(popInfo, vnf_info, instance, error)
  def recoverState(instance, error)
    logger.info "Recover state executed."
    puts Time.new
    @instance = instance
    callbackUrl = @instance['notification']
    ns_id = @instance['nsd_id']

    #reserved_resources for the instance
    logger.info "Removing reserved resources..."
    @instance['resource_reservation'].each do |resource|
      auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == resource['pop_id']}
      popInfo = getPopInfo(resource['pop_id'])
      popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

      begin
        tenant_token = openstackAuthentication(popUrls[:keystone], auth_info['tenant_id'], auth_info['username'], auth_info['password'])
        token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
      rescue => e
        logger.error "Unauthorized. Remove instance."
      end

      stack_url = resource['network_stack']['stack']['links'][0]['href']
      logger.debug "Removing reserved stack..."
      deleteStack(stack_url, tenant_token)
      status = "DELETING"
      count = 0
      while (status != "DELETE_COMPLETE" && status != "DELETE_FAILED")
        sleep(5)
        begin
          response = RestClient.get stack_url, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
          stack_info, error = parse_json(response)
          status = stack_info['stack']['stack_status']
        rescue Errno::ECONNREFUSED
          error = {"info" => "VIM unrechable."}
          return
        rescue RestClient::ResourceNotFound
          logger.info "Reserved stack already removed."
          status = "DELETE_COMPLETE"
          count = 21
        rescue => e
          puts e
          puts "If no exists means that is deleted correctly"
          status = "DELETE_COMPLETE"
          count = 21
          logger.error e
          logger.error e.response
        end

        logger.info "Try: " + count.to_s + ", status: " + status.to_s
        if (status == "DELETE_FAILED")
          deleteStack(stack_url, tenant_token)
          status = "DELETING"
        end
        count = count +1

        if count > 10
          logger.error "Reserved stack can not be removed"
          raise 400, "Reserved stack can not be removed"
        end
        break if count > 20
      end
      logger.info "Reserved stack removed correctly"
    end

    logger.info "Removing users and tenants..."
    @instance['vnfrs'].each do |vnf|
      puts vnf
      logger.error "Delete users for VNFR: " + vnf['vnfr_id'].to_s + " from PoP: " + vnf['pop_id'].to_s

      popInfo = getPopInfo(vnf['pop_id'])
      popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

      begin
        token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
      rescue => e
        logger.error "Unauthorized. Remove instance."
      end

      if (!vnf['security_group_id'].nil?)
#      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
      end

      logger.info "Removing user '" + vnf['user_id'].to_s + "'..."
      deleteUser(popUrls[:keystone], vnf['user_id'], token)
      #deleteTenant(popUrls[:keystone], vnf_info['tenant_id'], token)

    end

    message = {
        :code => 200,
        :info => "Removed correctly",
        :nsr_id => @instance['id'],
        :vnfrs => @instance['vnfrs']
    }
    generateMarketplaceResponse(callbackUrl, message)
    @instance.delete
  end

  # Instantiate a Network Service, finally calls the VNF Manager
  #
  # @param [JSON] message Instance
  # @param [JSON] message NSD
  # @return [Hash, nil] NS
  # @return [Hash, String] if the parsed message is an invalid JSON
  def instantiate(instance, nsd)

    @instance = instance
    callbackUrl = @instance['notification']
    flavour = @instance['service_deployment_flavour']
    slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }
    if slaInfo.nil?
      error = "SLA inconsistency"
      recoverState(@instance, error)
      return
    end
    sla_id = nsd['sla'].find { |sla| sla['sla_key'] == flavour }['id']
    logger.debug "SLA id: " + sla_id

    if settings.environment == 'development'
      infr_repo_url = { "host" => "", "port" => "" }
    else
      infr_repo_url = settings.infr_repository
    end

    #if PoP list has only one PoP, avoid execute ServiceMapping
    pops = getPops()
=begin
    if pops.size > 1


    else

    end
=end

    ms = {
        :NS_id => nsd['id'],
        :tenor_api => settings.manager,
        :infr_repo_api => infr_repo_url,
        :development => true,
        :NS_sla => sla_id,
        :overcommitting => "true"
    }
    #choose select mapping
    mapping = callMapping(ms, nsd)
    @instance.update_attribute('mapping_time', DateTime.now.iso8601(3).to_s)

    if (!mapping['vnf_mapping'])
      #halt 400, "Mapping: not enough resources."
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Mapping: not enough resources."))
      return
    end

    if @instance.nil?
      logger.error "Instance is null"
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: instance is null."))
      return
    end

    @instance.push(lifecycle_event_history: "MAPPED FOUND")
    logger.debug @instance

    @instance['vnfrs'] = Array.new
    @instance['authentication'] = Array.new

    #if mapping of all VNFs are in the same PoP. Create Authentication and network 1 time
    mapping['vnf_mapping'].each do |vnf|
      logger.info "Start authentication process of " + vnf.to_s
      pop_id = vnf['maps_to_PoP'].gsub('/pop/', '')
#      vnf_id = vnf['vnf'].delete('/')

      #check if this the authentication info is already created for this pop_id, if created, break the each
      logger.info "Check if authentication is created for this PoP"
      authentication = @instance['authentication'].find { |auth| auth['pop_id'] == pop_id }
      next if !authentication.nil?
      logger.info "Authentication not created for this PoP. Starting creation of credentials."

      pop_auth = {}
      pop_auth['pop_id'] = pop_id

      begin
        popInfo = getPopInfo(pop_id)
      rescue => e
        error = "Internal error: error getting pop information."
        logger.error error
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
        return
      end
      extra_info = popInfo['info'][0]['extrainfo']
      popUrls = getPopUrls(extra_info)
      pop_auth['urls'] = popUrls

      #create credentials for pop_id
      if popUrls[:keystone].nil? || popUrls[:orch].nil? || popUrls[:tenant].nil?
        logger.error 'Keystone and/or openstack urls missing'
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Keystone and/or openstack urls missing."))
        return
      end

      token = ""

      if @instance['project'].nil?
        begin
          token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])

          if (!settings.default_tenant_name.nil?)
            pop_auth['tenant_name'] = settings.default_tenant_name
            pop_auth['tenant_id'] = settings.default_tenant_id
          else
            pop_auth['tenant_name'] = "tenor_instance_" + @instance['id'].to_s
            pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token)
          end

          pop_auth['username'] = "user_" + @instance['id'].to_s
          pop_auth['password'] = "secretsecret"
          pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], token)

          logger.info "Created user with admin role."
          putRoleAdmin(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['user_id'], token)
          pop_auth['token'] = openstackAuthentication(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'])

          logger.info "Configuring Security Groups"
          pop_auth['security_group_id'] = configureSecurityGroups(popUrls[:compute], pop_auth['tenant_id'], pop_auth['token'])

          logger.info "Tenant id: " + pop_auth['tenant_id']
          logger.info "Username: " + pop_auth['username']
        rescue => e
          logger.error e
          error = {"info" => "Error creating the Openstack credentials."}
          logger.error error
          recoverState(@instance, error)
          return
        end
      end

      @instance['authentication'] << pop_auth
    end

   logger.info "Authentication generated"

    #check if @instance['authentication'] has the credentials for each PoP in mapping['vnf_mapping'] ? compare sizes?

    #generate networks in each PoP?
    if @instance['authentication'].size > 1
      logger.info "More than 1 PoP is defined."
      logger.info "WICM is required."

      # Request WICM to create a service
      wicm_message = {
          ns_instance_id: nsd['id'],
          client_mkt_id: '1',
          nap_mkt_id: '1',
          nfvi_mkt_id: '1'
      }

      begin
        response = RestClient.post settings.wicm + '/vnf-connectivity', wicm_message.to_json, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        error = {"info" => "WICM unreachable."}
        recoverState(@instance, error)
        return
      rescue => e
        logger.error e
        logger.error e.response
        error = {"info" => "Error with the WICM module."}
        recoverState(@instance, error)
        return
      end
      provider_info, error = parse_json(response)

      # Request HOT Generator to build the WICM - SFC integration
      provider_info['physical_network'] = 'sfcvlan'
      hot_template, errors = generateWicmHotTemplate(provider_info)

      #for each PoP, send the template
      resource_reservation = []
      @instance['authentication'].each do |auth|
        logger.info "WICM in POP  " + auth['pop_id']
        pop_id = auth['pop_id']
        pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == pop_id }
        popUrls = pop_auth['urls']

        logger.info "Send WICM template to HEAT Orchestration"
        stack_name = "WICM_SFC-" + @instance['id'].to_s
        template = {:stack_name => stack_name, :template => hot_template}
        stack, errors = sendStack(popUrls[:orch], vnf_info['tenant_id'], template, tenant_token)
        logger.error errors
        return 400, errors.to_json if errors
        #save WICM stack info in NSR

        # Wait for the WICM - SFC provisioning to finish
        status = "CREATING"
        count = 0
        while (status != "CREATE_COMPLETE" && status != "CREATE_FAILED")
          sleep(5)
          stack_info, errors = getStackInfo(popUrls[:orch], vnf_info['tenant_id'], stack_name, tenant_token)
          status = stack_info['stack']['stack_status']
          count = count +1
          break if count > 10
        end
        if (status == "CREATE_FAILED")
          logger.error "CREATE_FAILED"
          logger.error response
          recoverState(@instance, error)
          return
        end

        resource_reservation << {:wicm_stack => stack, :pop_id => pop_auth['pop_id']}
        @instance.update_attribute('resource_reservation', resource_reservation)
      end
    end

    if @instance['authentication'].size == 1
      logger.debug "Only 1 PoP is defined"
      #generate networks for this PoP
      pop_auth = @instance['authentication'][0]
      tenant_token = pop_auth['token']
      popUrls = pop_auth['urls']

      publicNetworkId = publicNetworkId(popUrls[:neutron], tenant_token)

      hot_generator_message = {
          nsd: nsd,
          public_net_id: publicNetworkId,
          dns_server: settings.dns_server
      }

      logger.info "Generating network HOT template..."
      hot, errors = generateNetworkHotTemplate(sla_id, hot_generator_message)
      return 400, errors.to_json if errors

      logger.info "Send network template to HEAT Orchestration"
      stack_name = "network-" + @instance['id'].to_s
      template = {:stack_name => stack_name, :template => hot}
      stack, errors = sendStack(popUrls[:orch], pop_auth['tenant_id'], template, tenant_token)
      logger.error errors
      return 400, errors.to_json if errors

      stack_id = stack['stack']['id']
      #@instance.update_attribute('network_stack', stack)

      logger.info "Checking network stack creation..."
      status = "CREATING"
      count = 0
      while (status != "CREATE_COMPLETE" && status != "CREATE_FAILED")
        sleep(5)
        stack_info, errors = getStackInfo(popUrls[:orch], pop_auth['tenant_id'], stack_name, tenant_token)
        status = stack_info['stack']['stack_status']
        count = count + 1
        break if count > 10
      end
      if (status == "CREATE_FAILED")
        logger.error "Error creating the stack."
        logger.error stack_info
        logger.error errors
        #recoverState(@instance, error)
        return
      end

      logger.info "Network stack CREATE_COMPLETE. Reading network information from stack..."
      sleep(3)
      network_resources, errors = getStackResources(popUrls[:orch], pop_auth['tenant_id'], stack_name, tenant_token)
      logger.error errors
      return 400, errors.to_json if errors
      stack_networks = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Net' }
      stack_routers = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Router' }

      networks = []
      stack_networks.each do |network|
        net, errors = getStackResource(popUrls[:orch], pop_auth['tenant_id'], stack_name, stack_id, network['resource_name'], tenant_token)
        networks.push({:id => net['resource']['attributes']['id'], :alias => net['resource']['attributes']['name']})
      end
      routers = []
      stack_routers.each do |router|
        router, errors = getStackResource(popUrls[:orch], pop_auth['tenant_id'], stack_name, stack_id, router['resource_name'], tenant_token)
        routers.push({:id => router['resource']['attributes']['id'], :alias => router['resource']['attributes']['name']})
      end
      @instance.push(lifecycle_event_history: "NETWORK CREATED")
      @instance.update_attribute('vlr', networks)
      @instance.update_attribute('routers', routers)
      resource_reservation = []
      resource_reservation << {:network_stack => stack, :pop_id => pop_auth['pop_id']}
      @instance.update_attribute('resource_reservation', resource_reservation)
    end


    vnfrs = []

    #for each VNF, instantiate
    mapping['vnf_mapping'].each do |vnf|
      logger.info "Start instantiation process of " + vnf.to_s
      pop_id = vnf['maps_to_PoP'].gsub('/pop/', '')
      vnf_id = vnf['vnf'].delete('/')
      pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == pop_id }
      popUrls = pop_auth['urls']

      #needs to be migrated to the VNFGFD
      sla_info = slaInfo['constituent_vnf'].find { |cvnf| cvnf['vnf_reference'] == vnf_id }
      if sla_info.nil?
        logger.error "NO SLA found with the VNF ID that has the NSD."
        error = {"info" => "Error with the VNF ID. NO SLA found with the VNF ID that has the NSD."}
        recoverState(@instance, error)
      end
      vnf_flavour = sla_info['vnf_flavour_id_reference']
      logger.info "VNF Flavour: " + vnf_flavour

      vnf_provisioning_info = {
          :ns_id => nsd['id'],
          :vnf_id => vnf_id,
          :flavour => vnf_flavour,
          :vim_id => pop_id,#popInfo['info'][0]['dcname'],
          :auth => {
              :url => {
                  :keystone => popUrls[:keystone],
                  :orch => popUrls[:orch]
              },
              :tenant => pop_auth['tenant_name'],
              :username => pop_auth['username'],
              :token => pop_auth['token'],
              :password => pop_auth['password']
          },
          :networks => @instance['vlr'],
          :routers => @instance['routers'],
          :security_group_id => pop_auth['security_group_id'],
          :dns_server => settings.dns_server,
          :callback_url => settings.manager + "/ns-instances/" + @instance['id'] + "/instantiate"
      }

      logger.info "Starting the instantiation of a VNF..."
      logger.debug vnf_provisioning_info
      @instance.push(lifecycle_event_history: "INSTANTIATING " + vnf_id.to_s + " VNF")
      @instance.update_attribute('instantiation_start_time', DateTime.now.iso8601(3).to_s)

      begin
        response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances', vnf_provisioning_info.to_json, :content_type => :json
      rescue => e
        logger.error "Rescue instatiation"
        logger.error e
        if (defined?(e.response)).nil?
          puts e.response.body
          error = "Instantiation error. Response from the VNF Manager: " + e.response.body
          generateMarketplaceResponse(marketplaceUrl, generateError(instantiation_info['ns_id'], "FAILED", error))
          return
        end
        logger.error "Handle error."
        return
      end

      vnfr, error = parse_json(response)
      logger.debug vnfr
      logger.debug "VNFr id: " + vnfr['_id'].to_s
      puts pop_auth

      pop_auth[:vnfd_id] = vnfr['vnfd_reference']
      pop_auth[:vnfi_id] = []
      pop_auth[:vnfr_id] = vnfr['_id']
      vnfrs << pop_auth

      @instance.update_attribute('vnfrs', vnfrs)

    end
    return

    #logger.debug "Calling SLA Enforcement"
    #each service_deployment_flavour has one or more assurance_parameters
    #sla_enforcement(nsd, @instance['id'].to_s)

  end
end