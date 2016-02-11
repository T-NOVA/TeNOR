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

  def instantiateVNF(instantiation_info)
    begin
      response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances', instantiation_info.to_json, :content_type => :json
    rescue => e
      logger.error e
      #if (defined?(e.response)).nil?
      #halt 503, "VNF-Manager unavailable"
      #end
      #halt e.response.code, e.response.body
    end
    puts e
    error = "Instantiation error"

    #generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
  end

  def generateMarketplaceResponse(marketplaceUrl, message)
    logger.error marketplaceUrl
    logger.error message.to_json
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

    #token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
    tenant_token = openstackAuthentication(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'])
    token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])


    if (!vnf_info['router_id'].nil?)
      ports = getRouterPorts(popUrls[:neutron], vnf_info['router_id'], tenant_token)
      ports.each do |port|
        if (port['tenant_id'] != "")
          updateRouterPorts(popUrls[:neutron], port['id'], tenant_token)
          deleteRouterPorts(popUrls[:neutron], port['id'], tenant_token)
        end
      end
    end

    if (!instance['vlr'].nil?)
      instance['vlr'].each do |network|
        deleteSubnet(popUrls[:neutron], network['subnet']['id'], tenant_token)
        #network['subnet'].each do |subnet|
        #  deleteSubnet(popUrls[:neutron], subnet['id'])
        #end
        deleteNetwork(popUrls[:neutron], network['id'], tenant_token)
      end
    end

    if (!vnf_info['router_id'].nil?)
      deleteRouter(popUrls[:neutron], vnf_info['router_id'], tenant_token)
    end


    if (!vnf_info['security_group_id'].nil?)
      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
    end

    deleteUser(popUrls[:keystone], vnf_info['user_id'], token)
    deleteTenant(popUrls[:keystone], vnf_info['tenant_id'], token)

    removeInstance(instance['id'])

    generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
  end

  def instantiate(instantiation_info)
    #start instantiation
    @instance = createInstance({})
    puts @instance

    callbackUrl = instantiation_info['callbackUrl']
    nsd = instantiation_info['nsd']
    flavour = instantiation_info['flavour']
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

    #DateTime.parse(@instance['mapping_time']).to_time.to_i
    @instance['mapping_time'] = Time.now
    updateInstance(@instance)
    puts "Mapping time: " + (DateTime.parse(@instance['mapping_time']).to_time.to_f*1000 - DateTime.parse(@instance['created_at']).to_time.to_f*1000).to_s

    return

    if (!mapping['vnf_mapping'])
      #halt 400, "Mapping: not enough resources."
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Mapping: not enough resources."))
    end

    #generate instance ID - Send instantiation to NS Instance repository
    #@instance = createInstance({:nsd_id => nsd['id'], :status => "INIT", :vendor => nsd['vendor'], :version => nsd['version'], :marketplace_callback => callbackUrl})
    #@instance = {:nsd_id => nsd['id'], :status => "INIT", :vendor => nsd['vendor'], :version => nsd['version'], :marketplace_callback => callbackUrl}
    #updateInstance(@instance)
    if @instance.nil?
      logger.error "Instance repo not connected"
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: instance repository not connected."))
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

      popInfo = getPopInfo(pop_id)
      extra_info = popInfo['info'][0]['extrainfo']
      vnf_info['pop_id'] = pop_id
      popUrls = getPopUrls(extra_info)

      token = ""
      tenant_token = ""

      if popUrls[:keystone].nil? || popUrls[:orch].nil? || popUrls[:neutron].nil? || popUrls[:compute].nil?
        logger.error 'Keystone and/or openstack urls missing'
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Keystone and/or openstack urls missing."))
      end

      if @instance['project'].nil?
        begin
          tenant_name = "tenor_instance_" + @instance['id'].to_s
          token = openstackAdminAuthentication(popUrls[:keystone], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
          vnf_info['tenant_id'] = createTenant(popUrls[:keystone], tenant_name, token)
          vnf_info['tenant_name'] = tenant_name
          vnf_info['username'] = "user_" + @instance['id'].to_s
          vnf_info['password'] = "secretsecret"
          vnf_info['user_id'] = createUser(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'], token)

          roleAdminId = getAdminRole(popUrls[:keystone], token)
          putRole(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['user_id'], roleAdminId, token)
          tenant_token = openstackAuthentication(popUrls[:keystone], vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'])
          secuGroupId = createSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], tenant_token)
          vnf_info['security_group_id'] = secuGroupId
          addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'TCP', tenant_token, 1, 65535)
          addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'UDP', tenant_token, 1, 65535)
          addRulesToTenant(popUrls[:compute], vnf_info['tenant_id'], secuGroupId, 'ICMP', tenant_token, -1, -1)
          puts "Tenant_id:" + vnf_info['tenant_id']
          puts "Username: " + vnf_info['username']

        rescue
          error = {"info" => "Error creating the Openstack credentials."}
          logger.error error
          recoverState(popInfo, vnf_info, @instance, error)
        end
      end

      logger.debug @instance

      networks = []
      publicNetworkId = publicNetworkId(popUrls[:neutron], tenant_token)
      vnf_info['router_id'] = createRouter(popUrls[:neutron], publicNetworkId, tenant_token)
      virtual_links = nsd['vld']['virtual_links']
      nsd['vld']['virtual_links'].each_with_index do |vlink, index|
        if vlink['flavor_ref_id'] == flavour
          logger.error vlink['merge']
          if (vlink['merge'])
            #TODO
            #use the same network
          end
          begin
            networkId = createNetwork(popUrls[:neutron], vlink['alias'], tenant_token)
            subnetId = createSubnetwork(popUrls[:neutron], networkId, index, tenant_token)
            addInterfaceToRouter(popUrls[:neutron], vnf_info['router_id'], subnetId, tenant_token)
            networks.push({:id => networkId, :alias => vlink['alias'], :subnet => {:id => subnetId}})
          rescue
            error = "Error creating networks or adding interfaces."
            logger.error error
            recoverState(popInfo, vnf_info, @instance, error)
          end
        end
      end

      @instance['vlr'] = networks
      @instance['vnf_info'] = vnf_info
      updateInstance(@instance)

      #VIM instantiation
      vnf_provisioning_info = {
          :ns_id => nsd['id'],
          :vnf_id => vnf_id,
          :flavour => flavour,
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
      puts "Instantiation..."
      logger.debug vnf_provisioning_info
      @instance['instantiation_start_time'] = Time.now
      instantiateVNF(vnf_provisioning_info)
    end
  end
end