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

  def callMapping(ms)

    begin
      response = RestClient.get settings.tenor_api + '/network-services/' + ms[:NS_id], :content_type => :json
    rescue => e
      return e.response.code, e.response.body
    end

    nsd, errors = parse_json(response)
    mapping = {
        "created_at" => "Thu Nov  5 10:13:25 2015",
        "vnf_mapping" =>
            [
                {
                    "maps_to_PoP" => "/pop/55ef7cce-1e9b-4b8f-9839-d40ceeb670f7",
                    "vnf" => "/" + nsd['vnfds'][0].to_s
                }
            ]
    }

    unsuccessfullMapping = {
        "Error" => "Error in MIP problem",
        "Info" => "MIP solution is undefined",
        "created_at" => "Thu Nov  5 10:11:37 2015"
    }

    if ms[:development]
      return mapping
    end

    begin
      response = RestClient.post settings.ns_mapping + '/mapper', ms.to_json, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        #halt 400, "NS-Mapping unavailable"
      end
      #halt e.response.code, e.response.body
    end

    mapping, errors = parse_json(response.body)
    return 400, errors if errors

    return mapping
  end

  def instantiateVNF(instantiation_info)
    begin
      response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances', instantiation_info.to_json, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        #halt 503, "VNF-Manager unavailable"
      end
      #halt e.response.code, e.response.body
    end
  end

  def getPopInfo(popId)

    popInfo = {
        "metadata" => {
            "source" => "T-Nova-AuthZ-Service"
        },
        "info" => [
            {
                "msg" => "Datacenter details.",
                "dcname" => "mypop-x",
                "adminuser" => "t-nova",
                "password" => "t-n0v@",
                "extrainfo" => "pop-ip=10.10.1.2 keystone-endpoint=http://10.10.1.2:35357/v2.0 orch-endpoint=http://10.10.1.2:8004/v1 neutron-endpoint=http://10.10.1.2:9696/v2.0 compute-endpoint=http://10.10.1.2:8774/v2"
            }
        ]
    }
    return popInfo

    begin
      popInfo = RestClient.get "#{settings.gatekeeper}/admin/dc/#{pop_id}", 'X-Auth-Token' => settings.token, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        error = {:info => "The PoP is not registered in Gatekeeper"}
        #marketplace URL here´
        #generateMarketplaceResponse()
        halt 503, "The PoP is not registered in Gatekeeper"
      end
    end
    halt e.response.code, e.response.body
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

  def recoverState(keystoneUrl, neutronUrl, vnf_info, instance_id, error, token)
    removeInstance(instance_id)
    if (!vnf_info['router_id'].nil?)
      deleteRouter(neutronUrl, vnf_info['router_id'], token)
    end
    deleteUser(keystoneUrl, vnf_info['user_id'], token)
    deleteTenant(keystoneUrl, vnf_info['tenant_id'], token)
    generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", error))
  end

  def instantiate(instantiation_info)
    #nsd = getNSD(ns['ns_id'].to_s)
    callbackUrl = instantiation_info['callbackUrl']

    nsd = instantiation_info['nsd']

    flavour = instantiation_info['flavour']

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

    if (!mapping['vnf_mapping'])
      #halt 400, "Mapping: not enough resources."
      generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Mapping: not enough resources."))
    end

    #generate instance ID - Send instantiation to NS Instance repository
    @instance = createInstance({:nsd_id => nsd['id'], :status => "INIT", :vendor => nsd['vendor'], :version => nsd['version'], :marketplace_callback => callbackUrl})
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

    @instance['vnfs'] = Array.new
    #@instance['vnfis'] = Array.new
    #for each VNF mapping, find the PoP information
    mapping['vnf_mapping'].each do |vnf|
      puts "Start instatination process of " + vnf.to_s
      pop_id = vnf['maps_to_PoP'].delete('/pop/')
      vnf_id = vnf['vnf'].delete('/')
      vnf_info = {}

      popInfo = getPopInfo(pop_id)
      vnf_info['pop_id'] = pop_id

      #VIM authentication
      extra_info = popInfo['info'][0]['extrainfo'].split(" ")

      keystoneUrl = ""
      orchUrl = ""
      neutronUrl = ""
      computeUrl = ""
      token = ""
      tenant_token = ""

      extra_info.each do |item|
        key = item.split('=')[0]
        if key == 'keystone-endpoint'
          keystoneUrl = item.split('=')[1]
        elsif key == 'orch-endpoint'
          orchUrl = item.split("=")[1]
        elsif key == 'neutron-endpoint'
          neutronUrl = item.split("=")[1]
        elsif key == 'compute-endpoint'
          computeUrl = item.split("=")[1]
        end
      end
      if keystoneUrl.nil? || orchUrl.nil? || neutronUrl.nil? || computeUrl.nil?
        logger.error 'Keystone and/or openstack urls missing'
        generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], "FAILED", "Internal error: Keystone and/or openstack urls missing."))
      end

      if @instance['project'].nil?
        begin
          tenant_name = "tenor_instance_" + @instance['id'].to_s
          token = openstackAdminAuthentication(keystoneUrl, popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
          vnf_info['tenant_id'] = createTenant(keystoneUrl, tenant_name, token)
          vnf_info['username'] = "user_" + @instance['id'].to_s
          vnf_info['password'] = "secretsecret"
          vnf_info['user_id'] = createUser(keystoneUrl, vnf_info['tenant_id'], vnf_info['username'], vnf_info['password'], token)

          roleAdminId = getAdminRole(keystoneUrl, token)
          putRole(keystoneUrl, vnf_info['tenant_id'], vnf_info['user_id'], roleAdminId, token)
          tenant_token = openstackAuthentication(keystoneUrl, tenant_name, vnf_info['username'], vnf_info['password'])
          secuGroupId = createSecurityGroup(computeUrl, vnf_info['tenant_id'], tenant_token)
          vnf_info['security_group_id'] = secuGroupId
          addRulesToTenant(computeUrl, vnf_info['tenant_id'], secuGroupId, 'TCP', tenant_token, 1, 65535)
          addRulesToTenant(computeUrl, vnf_info['tenant_id'], secuGroupId, 'UDP', tenant_token, 1, 65535)
          addRulesToTenant(computeUrl, vnf_info['tenant_id'], secuGroupId, 'ICMP', tenant_token, -1, -1)
          puts "Tenant_id:" + vnf_info['tenant_id']
          puts "Username: " + vnf_info['username']

        rescue
          error = {"info" => "Error creating the Openstack credentials."}
          logger.error error
          recoverState(keystoneUrl, neutronUrl, vnf_info, @instance['id'].to_s, error, token)
        end
      end

      logger.debug @instance

      networks = []
      publicNetworkId = publicNetworkId(neutronUrl, tenant_token)
      vnf_info['router_id'] = createRouter(neutronUrl, publicNetworkId, tenant_token)
      virtual_links = nsd['vld']['virtual_links']
      nsd['vld']['virtual_links'].each_with_index do |vlink, index|
        if vlink['flavor_ref_id'] == flavour
          logger.error vlink['merge']
          if(vlink['merge'])
            #TODO
            #use the same network
          end
          begin
            networkId = createNetwork(neutronUrl, vlink['alias'], tenant_token)
            subnetId = createSubnetwork(neutronUrl, networkId, index, tenant_token)
            addInterfaceToRouter(neutronUrl, @instance['router_id'], subnetId, tenant_token)
            networks.push({:id => networkId, :alias => vlink['alias'], :subnet => {:id => subnetId}})
          rescue
            error = "Error creating networks or adding interfaces."
            logger.error error
            recoverState(keystoneUrl, neturonUrl, vnf_info, @instance['id'].to_s, error, token)
          end
        end
      end

      @instance['networks'] = networks
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
                  :keystone => keystoneUrl,
                  :orch => orchUrl
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
      instantiateVNF(vnf_provisioning_info)
    end
  end
end