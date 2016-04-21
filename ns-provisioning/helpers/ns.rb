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
class NsProvisioner < Sinatra::Application

  def generateMarketplaceResponse(marketplaceUrl, message)
    logger.debug marketplaceUrl
    logger.debug message.to_json
    begin
      response = RestClient.post marketplaceUrl, message.to_json, :content_type => :json
    rescue RestClient::ResourceNotFound
      puts "No exists in the Marketplace."
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
    callbackUrl = instance['notification']
    ns_id = instance['nsd_id']

    tenant_token = openstackAuthentication(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'])
    token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])

    if (instance['network_stack'])
      stack_url = instance['network_stack']['stack']['links'][0]['href']
      logger.error "Removing network stack"
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
          #recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue RestClient::ResourceNotFound
          logger.info "Network already removed."
          status = "DELETE_COMPLETE"
        rescue => e
          puts "If no exists means that is deleted correctly"
          status = "DELETE_COMPLETE"
          logger.error e
          logger.error e.response
        end

        puts status
        if (status == "DELETE_FAILED")
          deleteStack(stack_url, tenant_token)
          status = "DELETING"
        end
        count = count +1
        break if count > 10
      end

      logger.info "Network stack removed correctly"
    end
    if (!vnf_info['security_group_id'].nil?)
#      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
    end

    puts "Removing user..."
    deleteUser(popUrls[:keystone], vnf_info['user_id'], token)
    #    deleteTenant(popUrls[:keystone], vnf_info['tenant_id'], token)

    #removeInstance(instance)
    instance.delete

    generateMarketplaceResponse(callbackUrl, generateError(ns_id, "INFO", "Removed correctly"))
  end

  def instantiate(instance, nsd)

    @instance = instance

    puts "Instance1"
    callbackUrl = @instance['notification']
    flavour = @instance['service_deployment_flavour']
    slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }
    if slaInfo.nil?
      error = "SLA inconsistency"
      recoverState(popInfo, vnf_info, @instance, error)
      return
    end
    sla_id = nsd['sla'].find { |sla| sla['sla_key'] == flavour }['id']
    puts sla_id

    infr_repo_url = @tenor_modules.select {|service| service["name"] == "infr_repository" }[0]

    ms = {
        :NS_id => nsd['id'],
        :tenor_api => settings.manager,
        :infr_repo_api => infr_repo_url['host'].to_s + ":" + infr_repo_url['port'].to_s,
        :development => true,
        :NS_sla => sla_id,
        :overcommitting => "true"
    }
    #choose select mapping
    mapping = callMapping(ms)
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

          if (!settings.default_tenant_name.nil?)
            tenant_name = settings.default_tenant_name
            tenant_id = settings.default_tenant_id
          elsif tenant_name = "tenor_instance_" + @instance['id'].to_s
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
          if (!settings.default_tenant_name.nil?)
            vnf_info['security_group_id'] = security_groups['security_groups'][0]['id']
          elsif secuGroupId = createSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], tenant_token)
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

      hot_url = @tenor_modules.select {|service| service["name"] == "hot_generator" }[0]

      if false
        # Request WICM to create a service
        wicm_message = {
            ns_instance_id: nsd['id'],
            client_mkt_id: '1',
            nap_mkt_id: '1',
            nfvi_mkt_id: '1'
        }
        wicm_url = @tenor_modules.select {|service| service["name"] == "wicm" }[0]

        begin
          response = RestClient.post wicm_url['host'].to_s + ":" + wicm_url['port'].to_s + '/vnf-connectivity', wicm_message.to_json, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
          error = {"info" => "WICM unreachable."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          logger.error e
          logger.error e.response
          error = {"info" => "Error with the WICM module."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end
        provider_info, error = parse_json(response)

        # Request HOT Generator to build the WICM - SFC integration
        provider_info['physical_network'] = 'sfcvlan'
        begin
          response = RestClient.post hot_url['host'].to_s + ":" + hot_url['port'].to_s + '/wicmhot', provider_info.to_json, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
          error = {"info" => "HOT Generator unreachable."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        rescue => e
          logger.error e
          logger.error e.response
          error = {"info" => "Error creating the network stack."}
          recoverState(popInfo, vnf_info, @instance, error)
          return
        end
        hot_template, error = parse_json(response)

        # Provision the WICM - SFC integration
        template = {:stack_name => "WICM_SFC-" + @instance['id'].to_s, :template => hot_template}
        begin
          response = RestClient.post "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks", template.to_json, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
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
        while (status != "CREATE_COMPLETE" && status != "CREATE_FAILED")
          sleep(5)
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
        if (status == "CREATE_FAILED")
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

      puts "Generating network HOT template..."
      begin
        response = RestClient.post hot_url['host'].to_s + ":" + hot_url['port'].to_s + '/networkhot/' + sla_id, hot_generator_message.to_json, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        error = {"info" => "HOT Generator unrechable."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      rescue => e
        logger.error e.response
        recoverState(popInfo, vnf_info, @instance, e.response)
        return
      end
      hot, error = parse_json(response)

      puts "Send network template to HEAT Orchestration"
      template = {:stack_name => "network-" + @instance['id'].to_s, :template => hot}
      begin
        response = RestClient.post "#{popUrls[:orch]}/#{vnf_info['tenant_id']}/stacks", template.to_json, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        error = {"info" => "VIM unrechable."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      rescue => e
        logger.error e
        error = {"info" => "Error creating the network stack."}
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end
      stack, error = parse_json(response)
      stack_id = stack['stack']['id']
      #@instance['network_stack'] = stack
      @instance.update_attribute('network_stack', stack)
      #instance.update_attributes(@instance)

      puts "Check network stack creation..."
      #stack_status
      status = "CREATING"
      count = 0
      while (status != "CREATE_COMPLETE" && status != "CREATE_FAILED")
        sleep(5)
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
      if (status == "CREATE_FAILED")
        recoverState(popInfo, vnf_info, @instance, error)
        return
      end

      puts "Network stack CREATE_COMPLETE. Getting network information..."
      #get network info to stack
      sleep(3)
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

      @instance.update_attribute('vlr', networks)
      @instance.update_attribute('vnf_info', vnf_info)
      #@instance['vlr'] = networks
      #@instance['vnf_info'] = vnf_info
      #@instance.update_attributes(@instance)

      #needs to be migrated to the VNFGFD
      vnf_flavour = slaInfo['constituent_vnf'].find { |cvnf| cvnf['vnf_reference'] == vnf_id }['vnf_flavour_id_reference']
      puts vnf_flavour

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
          :callback_url => settings.manager + "/ns-instances/" + @instance['id'] + "/instantiate"
      }

      puts "Instantiation VNF..."
      logger.debug vnf_provisioning_info
      @instance.update_attribute('instantiation_start_time', DateTime.now.iso8601(3).to_s)
      #@instance['instantiation_start_time'] = DateTime.now.iso8601(3)
      #@instance.update_attributes(@instance)

      url = @tenor_modules.select {|service| service["name"] == "vnf_manager" }[0]
      begin
        response = RestClient.post url['host'].to_s + ":" + url['port'].to_s + '/vnf-provisioning/vnf-instances', vnf_provisioning_info.to_json, :content_type => :json
      rescue => e
        puts "Rescue instatiation"
        logger.error e
        if (defined?(e.response)).nil?
          puts e.response.body
          error = "Instantiation error. Response from the VNF Manager: " + e.response.body
          generateMarketplaceResponse(marketplaceUrl, generateError(instantiation_info['ns_id'], "FAILED", error))
          return
        end
      end

      vnfr, error = parse_json(response)
      puts vnfr
      puts vnfr['_id']
      #@instance['vnfr'] = vnfr['id']

      vnfrs = []
      vnf_info = {}
      vnf_info[:vnfd_id] = vnfr['vnfd_reference']
      vnf_info[:vnfi_id] = nil
      vnf_info[:vnfr_id] = vnfr['_id']
      vnfrs << vnf_info

      @instance.update_attribute('vnfr', vnfrs)

    end
  end
end