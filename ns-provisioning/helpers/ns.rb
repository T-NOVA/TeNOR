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

  def instantiateVNF(marketplaceUrl, instantiation_info)
    begin
      response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances', instantiation_info.to_json, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        puts e.response.body
        error = "Instantiation error. Response from the VNF Manager: " + e.response.body
        generateMarketplaceResponse(marketplaceUrl, generateError(instantiation_info['ns_id'], "FAILED", error))
      end
    end

  end

  def generateMarketplaceResponse(marketplaceUrl, message)
    logger.debug marketplaceUrl
    logger.debug message.to_json
    begin
      response = RestClient.post marketplaceUrl, message.to_json, :content_type => :json
    rescue => e
      logger.error e
      #halt e.response.code, e.response.body
    end
  end

  def generateError(ns_id, status, message)
    message = {
        :nsd_id => ns_id,
        :status => status,
        :cause => message
    }
    return message
  end

  def recoverState(popInfo, vnf_info, instance, error)

    popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])
    callbackUrl = instance['marketplace_callback']
    ns_id = instance['nsd_id']

    tenant_token = openstackAuthentication(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'])
    token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])

    #stack_name = instance['network_stack']['stack']['stack_name']
    #stack_id = instance['network_stack']['stack']['id']
    if(instance['network_stack'])
      stack_url = instance['network_stack']['stack']['links'][0]['href']
      logger.error "Removing network stack"
      deleteStack(stack_url, tenant_token)

      status = "DELETING"
      count = 0
      while(status != "DELETE_COMPLETE" && status != "DELETE_FAILED")
        sleep(3)
        begin
          response = RestClient.get stack_url, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
          error = {"info" => "VIM unrechable."}
          #recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          puts "If no exists means that is deleted correctly"
          status = "DELETE_COMPLETE"
          logger.error e
          logger.error e.response
        end
        stack_info, error = parse_json(response)
        status = stack_info['stack']['stack_status']
        puts status
        if( status == "DELETE_FAILED" )
          deleteStack(stack_url, tenant_token)
        end
        count = count +1
        break if count > 10
      end

      logger.error "Network stack removed correctly"
    end
    if (!vnf_info['security_group_id'].nil?)
#      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
    end

    puts "Removing user..."
    deleteUser(popUrls[:keystone], vnf_info['user_id'], token)
#    deleteTenant(popUrls[:keystone], vnf_info['tenant_id'], token)

    removeInstance(instance)

    generateMarketplaceResponse(callbackUrl, generateError(ns_id, "INFO", "Removed correctly"))
  end

  def instantiate(instantiation_info)

    callbackUrl = instantiation_info['callbackUrl']
    nsd = instantiation_info['nsd']
    flavour = instantiation_info['flavour']

    if flavour.nil?
      error = "Flavour is null"
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
    end

    begin
      @instance = createInstance({})
    rescue => e
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FATAL", e))
      return
    end

    puts @instance

    @instance = @instance.merge(
        {
            :nsd_id => nsd['id'],
            :descriptor_reference => nsd['id'],
            :auto_scale_policy => nsd['auto_scale_policy'],
            :connection_points => nsd['connection_points'],
            :monitoring_parameters => nsd['monitoring_parameters'],
            :service_deployment_flavour => flavour,
            :vendor => nsd['vendor'],
            :version => nsd['version'],
            #vlr
            #vnfrs
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
            :marketplace_callback => callbackUrl
        }
    )

    ms = {
        :NS_id => nsd['id'],
        :tenor_api => settings.tenor_api,
        :infr_repo_api => settings.infr_repo_api,
        :ir_simulation => "true",
        :ns_simulation => "true",
        :development => true,
        :NS_sla => flavour
    }
    #choose select mapping
    mapping = callMapping(ms)

    @instance['mapping_time'] = DateTime.now.iso8601(3)
    begin
      updateInstance(@instance)
    rescue => e
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FATAL", e))
      return
    end

    puts "Mapping time: " + (DateTime.parse(@instance['mapping_time']).to_time.to_f*1000 - DateTime.parse(@instance['created_at']).to_time.to_f*1000).to_s

    if (!mapping['vnf_mapping'])
      #halt 400, "Mapping: not enough resources."
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Mapping: not enough resources."))
      return
    end

    if @instance.nil?
      logger.error "Instance repo not connected"
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: instance repository not connected."))
      return
    end

    logger.debug @instance

    #logger.debug "Calling SLA Enforcement"
    #each service_deployment_flavour has one or more assurance_parameters
    #sla_enforcement(nsd, @instance['id'].to_s)

    #call NS monitoring
    #monitoringData(nsd)

    @instance['vnfrs'] = Array.new
    mapping['vnf_mapping'].each do |vnf|
      puts "Start instatination process of " + vnf.to_s
      pop_id = vnf['maps_to_PoP'].delete('/pop/')
      vnf_id = vnf['vnf'].delete('/')
      vnf_info = {}

      begin
        popInfo = getPopInfo(pop_id)
      rescue => e
        error = "Internal error: error getting pop information."
        logger.error error
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
        return
      end
      extra_info = popInfo['info'][0]['extrainfo']
      vnf_info['pop_id'] = pop_id
      popUrls = getPopUrls(extra_info)

      token = ""
      tenant_token = ""

      if popUrls[:keystone].nil? || popUrls[:orch].nil? || popUrls[:neutron].nil? || popUrls[:compute].nil?
        logger.error 'Keystone and/or openstack urls missing'
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Keystone and/or openstack urls missing."))
        return
      end

      if @instance['project'].nil?
        begin

          token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])

          if(!settings.default_tenant_name.nil?)
            tenant_name = settings.default_tenant_name
            tenant_id = settings.default_tenant_id
          elsif
            tenant_name = "tenor_instance_" + @instance['id'].to_s
            tenant_id = createTenant(popUrls[:keystone], tenant_name, token)
          end

          vnf_info['tenant_id'] = tenant_id
          vnf_info['tenant_name'] = tenant_name
          vnf_info['username'] = "user_" + @instance['id'].to_s
          vnf_info['password'] = "secretsecret"
          vnf_info['user_id'] = createUser(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'], token)

          roleAdminId = getAdminRole(popUrls[:keystone], token)
          putRole(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['user_id'], roleAdminId, token)
          tenant_token = openstackAuthentication(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'])
          security_groups = getSecurityGroups(popUrls[:compute], vnf_info['tenant_id'], tenant_token)
          puts security_groups['security_groups'][0]
          if(!settings.default_tenant_name.nil?)
            vnf_info['security_group_id'] = security_groups['security_groups'][0]['id']
          elsif
            secuGroupId = createSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], tenant_token)
            vnf_info['security_group_id'] = secuGroupId
            addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'TCP', tenant_token, 1, 65535)
            addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'UDP', tenant_token, 1, 65535)
            addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'ICMP', tenant_token, -1, -1)
          end

          puts "Tenant id: " + vnf_info['tenant_id']
          puts "Username: " + vnf_info['username']

        rescue
          error = {"info" => "Error creating the Openstack credentials."}
          logger.error error
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end
      end

      logger.debug @instance

      if false
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
          halt 500, 'WICM unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        provider_info, error = parse_json(response)

        # Request HOT Generator to build the WICM - SFC integration
        provider_info['security_group_id'] = vnf_info['security_group_id']
        provider_info['physical_network'] = 'sfcvlan'
        begin
          response = RestClient.post settings.hot_generator + '/wicmhot', provider_info.to_json, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'HOT Generator unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        hot_template, error = parse_json(response)

        # Provision the WICM - SFC integration
        template = {:stack_name => "WICM_SFC-" + @instance['id'].to_s, :template => hot_template}
        begin
          response = RestClient.post "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks", template.to_json , 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
          error = {"info" => "VIM unrechable."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          logger.error e
          logger.error e.response
          error = {"info" => "Error creating the network stack."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end

        # Wait for the WICM - SFC provisioning to finish
        status = "CREATING"
        count = 0
        while(status != "CREATE_COMPLETE" || status != "CREATE_FAILED")
          sleep(1)
          begin
            response = RestClient.get "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks/#{"WICM_SFC-" + @instance['id'].to_s}", 'X-Auth-Token' => tenant_token
          rescue Errno::ECONNREFUSED
            error = {"info" => "VIM unrechable."}
            recoverState(popInfo, vnf_info, @instance, error)
            return
          rescue => e
            logger.error e
            logger.error e.response
            error = {"info" => "Error creating the network stack."}
            recoverState(popInfo, vnf_info, @instance, error)
            return
          end
          stack_info, error = parse_json(response)
          status = stack_info['stack']['stack_status']
          count = count +1
          break if count > 10
        end
        if(status == "CREATE_FAILED")
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end

      end

      publicNetworkId = publicNetworkId(popUrls[:neutron], tenant_token)

      hot_generator_message = {
          nsd: nsd,
          public_net_id: publicNetworkId,
          dns_server: settings.dns_server
      }

      slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }
      if slaInfo.nil?
        error = "SLA inconsistency"
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end

      nsd_flavour = slaInfo['id']
      puts nsd_flavour

      puts "Generating network HOT template..."
      begin
        response = RestClient.post settings.hot_generator + '/networkhot/' + nsd_flavour, hot_generator_message.to_json, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        halt 500, 'HOT Generator unreachable'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end
      hot, error = parse_json(response)

      puts "Send network template to HEAT Orchestration"
      template = {:stack_name => "network-" + @instance['id'].to_s, :template => hot}
      begin
        response = RestClient.post "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks", template.to_json , 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        error = {"info" => "VIM unrechable."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      rescue => e
        logger.error e
        logger.error e.response
        error = {"info" => "Error creating the network stack."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end
      stack, error = parse_json(response)
      stack_id = stack['stack']['id']

      puts "Check network stack creation..."
      #stack_status
      status = "CREATING"
      count = 0
      while(status != "CREATE_COMPLETE" || status != "CREATE_FAILED")
        sleep(1)
        begin
          response = RestClient.get "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks/#{"network-" + @instance['id'].to_s}", 'X-Auth-Token' => tenant_token
        rescue Errno::ECONNREFUSED
          error = {"info" => "VIM unrechable."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          logger.error e
          logger.error e.response
          error = {"info" => "Error creating the network stack."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end
        stack_info, error = parse_json(response)
        status = stack_info['stack']['stack_status']
        count = count +1
        break if count > 10
      end
      if(status == "CREATE_FAILED")
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end

      puts "Network stack CREATE_COMPLETE. Getting network information..."
      #get network info to stack
      begin
        response = RestClient.get "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks/#{"network-" + @instance['id'].to_s}/resources", 'X-Auth-Token' => tenant_token
      rescue Errno::ECONNREFUSED
        error = {"info" => "VIM unrechable."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      rescue => e
        logger.error e
        logger.error e.response
        error = {"info" => "Error creating the network stack."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end
      network_resources, error = parse_json(response)
      stack_networks = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Net' }

      puts "Reading network information from stack..."
      networks = []
      #for each network, get resource info
      stack_networks.each do |network|
        begin
          response = RestClient.get "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks/#{"network-" + @instance['id'].to_s}/#{stack_id}/resources/#{network['resource_name']}", 'X-Auth-Token' => tenant_token
        rescue Errno::ECONNREFUSED
          error = {"info" => "VIM unrechable."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          logger.error e
          logger.error e.response
          error = {"info" => "Error creating the network stack."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end
        net, error = parse_json(response)
        networks.push({:id => net['resource']['attributes']['id'], :alias => net['resource']['attributes']['name']})
      end

      stack['stack_name'] = "network-" + @instance['id'].to_s
      @instance['network_stack'] = stack
      @instance['vlr'] = networks
      @instance['vnf_info'] = vnf_info
      updateInstance(@instance)

      slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }
      if slaInfo.nil?
        error = "SLA inconsistency"
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end
      #vnf_flavour = slaInfo['constituent_vnf'].find { |cvnf| cvnf['vnf_reference'] == vnf_id }['vnf_flavour_id_reference']
      vnf_flavour = slaInfo['id']

      vnf_provisioning_info = {
          :ns_id => nsd['id'],
          :vnf_id => vnf_id,
          :flavour => vnf_flavour,
          :vim_id => popInfo['info'][0]['dcname'],
          :auth => {
              :url => {
                  :keystone => popUrls[:keystone],
                  :orch => popUrls[:orch]
              },
              :tenant => tenant_name,
              :username => vnf_info['username'],
              :password => vnf_info['password']
          },
          :networks => networks,
          :security_group_id => vnf_info['security_group_id'],
          :callback_url => settings.tenor_api + "/ns-instances/" + @instance['id'] + "/instantiate"
      }
      puts "Instantiation VNF..."
      logger.debug vnf_provisioning_info
      @instance['instantiation_start_time'] = DateTime.now.iso8601(3)
      updateInstance(@instance)
      begin
        instantiateVNF(callbackUrl, vnf_provisioning_info)
      rescue => e
        logger.error e
        error = {"info" => "Error in the instantiation. (VNF Manager error)"}
        logger.error error
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end

    end
  end
end