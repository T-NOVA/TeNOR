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
    # @param [JSON] notification_url Notification URL
    # @param [JSON] message The message to send
    def generateMarketplaceResponse(notification_url, message)
        logger.error message
        logger.debug 'Notification url: ' + notification_url
        begin
            response = RestClient.post notification_url, message.to_json, content_type: :json
        rescue RestClient::ResourceNotFound
            logger.error 'Error sending the callback to the marketplace. Resource not found.'
        rescue => e
            logger.error e
        end
    end

    # Generates a standard Hash for errors.
    #
    # @param [JSON] ns_id NSr id
    # @param [JSON] status Status
    # @param [JSON] message Message
    # @return [Hash] The error message
    def generateError(ns_id, status, message)
        message = {
            nsd_id: ns_id,
            status: status,
            cause: message
        }
        message
    end

    # Recover the state due to fail during the instatiation or when the instance should be removed
    #
    # @param [JSON] instance NSr
    # @return [Hash, nil] NS
    # @return [Hash, String] if the parsed message is an invalid JSON
    # def recoverState(popInfo, vnf_info, instance, error)
    def recoverState(instance, _error)
        logger.info 'Recover state executed.'
        @instance = instance
        @instance.update_attribute('status', 'DELETING')
        callback_url = @instance['notification']
        ns_id = @instance['nsd_id']

        # reserved_resources for the instance
        logger.info 'Removing reserved resources...'
        @instance['resource_reservation'].each do |resource|
            break if resource['pop_id'].nil?

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == resource['pop_id'] }
            popInfo, errors = getPopInfo(resource['pop_id'])
            logger.error errors if errors
            return 400, errors.to_json if errors
            popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

            begin
                tenant_token = openstackAuthentication(popUrls[:keystone], auth_info['tenant_id'], auth_info['username'], auth_info['password'])
                token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
            rescue => e
                logger.error 'Unauthorized. Remove instance.'
            end

            stack_url = resource['network_stack']['stack']['links'][0]['href']
            logger.debug 'Removing reserved stack...'
            response, errors = delete_stack_with_wait(stack_url, tenant_token)
            logger.error errors if errors
            halt 400, errors if errors
            logger.info 'Reserved stack removed correctly'
        end

        logger.info 'Removing users and tenants...'
        @instance['vnfrs'].each do |vnf|
            logger.error 'Delete users for VNFR: ' + vnf['vnfr_id'].to_s + ' from PoP: ' + vnf['pop_id'].to_s

            popInfo, errors = getPopInfo(vnf['pop_id'])
            logger.error errors if errors
            return 400, errors.to_json if errors
            popUrls = getPopUrls(popInfo['info'][0]['extrainfo'])

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == vnf['pop_id'] }
            puts popInfo

            begin
                token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
            rescue => e
                logger.error 'Unauthorized. Remove instance.'
            end

            unless vnf['security_group_id'].nil?
                #      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
            end

            logger.info "Removing user '" + auth_info['user_id'].to_s + "'..."
            deleteUser(popUrls[:keystone], auth_info['user_id'], token)

            unless settings.default_tenant
                logger.info "Removing tenant '" + auth_info['tenant_id'].to_s + "'..."
                # deleteTenant(popUrls[:keystone], auth_info['tenant_id'], token)
            end
        end

        message = {
            code: 200,
            info: 'Removed correctly',
            nsr_id: @instance['id'],
            vnfrs: @instance['vnfrs']
        }
        generateMarketplaceResponse(callback_url, message)
        @instance.delete
    end

    # Instantiate a Network Service, finally calls the VNF Manager
    #
    # @param [JSON] message Instance
    # @param [JSON] message NSD
    # @return [Hash, nil] NS
    # @return [Hash, String] if the parsed message is an invalid JSON
    def instantiate(instance, nsd, instantiation_info)
        @instance = instance
        callback_url = @instance['notification']
        flavour = @instance['service_deployment_flavour']
        pop_list = instantiation_info['pop_list']
        pop_id = instantiation_info['pop_id']
        mapping_id = instantiation_info['mapping_id']
        nap_id = instantiation_info['nap_id']
        customer_id = instantiation_info['customer_id']
        slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }
        if slaInfo.nil?
            return generateMarketplaceResponse(callbackUrl, generateError(nsd['id'], 'FAILED', 'Internal error: SLA inconsistency'))
        end
        sla_id = nsd['sla'].find { |sla| sla['sla_key'] == flavour }['id']
        logger.debug 'SLA id: ' + sla_id

        infr_repo_url = if settings.environment == 'development'
                            { 'host' => '', 'port' => '' }
                        else
                            settings.infr_repository
                        end

        logger.info 'List of available PoPs:'
        logger.info pop_list

        if pop_id.nil? && mapping_id.nil?
            logger.info 'Request from Marketplace.'
            pop_id = pop_list[0] if pop_list.size == 1
        elsif !mapping_id.nil?
            # call specified mapping with the id
            # TODO
        end

        if !pop_id.nil?
            logger.debug 'Deploy to PoP id: ' + pop_id.to_s
            mapping = getMappingResponse(nsd, pop_id)
        else
            ms = {
                NS_id: nsd['id'],
                tenor_api: settings.manager,
                infr_repo_api: infr_repo_url,
                development: true,
                NS_sla: sla_id,
                overcommitting: 'true'
            }
            mapping, errors = callMapping(ms, nsd)
            # mapping Mapper PoPs with gatekeeper PoPs.
            return generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', 'Internal error: Mapping not reachable.')) if errors
        end

        @instance.update_attribute('mapping_time', DateTime.now.iso8601(3).to_s)

        unless mapping['vnf_mapping']
            generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', 'Internal error: Mapping: not enough resources.'))
            return
        end

        if @instance.nil?
            generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', 'Internal error: instance is null.'))
            return
        end

        @instance.push(lifecycle_event_history: 'MAPPED FOUND')
        logger.debug @instance

        @instance['vnfrs'] = []
        @instance['authentication'] = []

        # if mapping of all VNFs are in the same PoP. Create Authentication and network 1 time
        mapping['vnf_mapping'].each do |vnf|
            logger.info 'Start authentication process of ' + vnf.to_s
            pop_id = vnf['maps_to_PoP'].gsub('/pop/', '')

            # check if this the authentication info is already created for this pop_id, if created, break the each
            logger.info 'Check if authentication is created for this PoP'
            authentication = @instance['authentication'].find { |auth| auth['pop_id'] == pop_id }
            next unless authentication.nil?
            logger.info 'Authentication not created for this PoP. Starting creation of credentials.'

            pop_auth = {}
            pop_auth['pop_id'] = pop_id

            popInfo, errors = getPopInfo(pop_id)
            logger.error errors if errors
            generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', 'Internal error: error getting pop information.')) if errors
            return 400, errors.to_json if errors

            extra_info = popInfo['info'][0]['extrainfo']
            popUrls = getPopUrls(extra_info)
            pop_auth['urls'] = popUrls

            # create credentials for pop_id
            if popUrls[:keystone].nil? || popUrls[:orch].nil? || popUrls[:tenant].nil?
                generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', 'Internal error: Keystone and/or openstack urls missing.'))
                return
            end

            token = ''

            if @instance['project'].nil?
                begin
                    token = openstackAdminAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
                    
                    if settings.default_tenant
                        pop_auth['username'] = settings.default_user_name
                        pop_auth['tenant_name'] = settings.default_tenant_name
                        pop_auth['tenant_id'] = getTenantId(popUrls[:keystone], pop_auth['tenant_name'], token)
                        pop_auth['user_id'] = getUserId(popUrls[:keystone], pop_auth['username'], token)
                        pop_auth['password'] = 'secretsecret'
                        if pop_auth['tenant_id'].nil?
                            pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token)
                        end
                        if pop_auth['user_id'].nil?
                            pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], token)
                        end
                    else
                        pop_auth['tenant_name'] = 'tenor_instance_' + @instance['id'].to_s
                        pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token)
                        pop_auth['username'] = 'user_' + @instance['id'].to_s
                        pop_auth['password'] = 'secretsecret'
                        pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], token)
                    end


                    logger.info 'Created user with admin role.'
                    putRoleAdmin(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['user_id'], token)

                    logger.info 'Authentication using new user credentials.'
                    pop_auth['token'] = openstackAuthentication(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'])

                    logger.info 'Configuring Security Groups'
                    pop_auth['security_group_id'] = configureSecurityGroups(popUrls[:compute], pop_auth['tenant_id'], pop_auth['token'])

                    logger.info 'Tenant id: ' + pop_auth['tenant_id']
                    logger.info 'Username: ' + pop_auth['username']
                rescue => e
                    logger.error e
                    error = { 'info' => 'Error creating the Openstack credentials.' }
                    logger.error error
                    recoverState(@instance, error)
                    return
                end
            end

            @instance['authentication'] << pop_auth
        end

        logger.info 'Authentication generated'

        # check if @instance['authentication'] has the credentials for each PoP in mapping['vnf_mapping'] ? compare sizes?

        # generate networks in each PoP?
        if @instance['authentication'].size > 1
            logger.info 'More than 1 PoP is defined.'
            logger.info 'WICM is required.'

            # Request WICM to create a service
            wicm_message = {
                ns_instance_id: @instance['id'].to_s,
                client_mkt_id: customer_id,
                nap_mkt_id: nap_id,
                nfvi_mkt_id: '1'
            }

            begin
                response = RestClient.post settings.wicm + '/vnf-connectivity', wicm_message.to_json, content_type: :json, accept: :json
            rescue Errno::ECONNREFUSED
                error = { 'info' => 'WICM unreachable.' }
                recoverState(@instance, error)
                return
            rescue => e
                logger.error e
                logger.error e.response
                error = { 'info' => 'Error with the WICM module.' }
                recoverState(@instance, error)
                return
            end
            provider_info, error = parse_json(response)

            # Request HOT Generator to build the WICM - SFC integration
            provider_info['physical_network'] = 'sfcvlan'
            hot_template, errors = generateWicmHotTemplate(provider_info)

            # for each PoP, send the template
            resource_reservation = []
            @instance['authentication'].each do |auth|
                logger.info 'WICM in POP  ' + auth['pop_id']
                pop_id = auth['pop_id']
                pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == pop_id }
                popUrls = pop_auth['urls']

                logger.info 'Send WICM template to HEAT Orchestration'
                stack_name = 'WICM_SFC_' + @instance['id'].to_s
                template = { stack_name: stack_name, template: hot_template }
                stack, errors = sendStack(popUrls[:orch], vnf_info['tenant_id'], template, tenant_token)
                logger.error errors
                return 400, errors.to_json if errors
                # save WICM stack info in NSR

                # Wait for the WICM - SFC provisioning to finish
                stack_info, errors = create_stack_wait(popUrls[:orch], vnf_info['tenant_id'], stack_name, tenant_token, 'NS WICM')
                return 400, errors.to_json if errors

                resource_reservation = @instance['resource_reservation']
                resource_reservation << { wicm_stack: stack, pop_id: pop_auth['pop_id'] }
                @instance.update_attribute('resource_reservation', resource_reservation)
            end
        end

        if @instance['authentication'].size == 1
            logger.debug 'Only 1 PoP is defined'
            # generate networks for this PoP
            pop_auth = @instance['authentication'][0]
            tenant_token = pop_auth['token']
            popUrls = pop_auth['urls']

            publicNetworkId = publicNetworkId(popUrls[:neutron], tenant_token)

            hot_generator_message = {
                nsr_id: @instance['id'],
                nsd: nsd,
                public_net_id: publicNetworkId,
                dns_server: popUrls[:dns]
            }

            logger.info 'Generating network HOT template...'
            hot, errors = generateNetworkHotTemplate(sla_id, hot_generator_message)
            return 400, errors.to_json if errors

            logger.info 'Send network template to HEAT Orchestration'
            stack_name = 'network_' + @instance['id'].to_s
            template = { stack_name: stack_name, template: hot }
            stack, errors = sendStack(popUrls[:orch], pop_auth['tenant_id'], template, tenant_token)
            logger.error errors if errors
            return 400, errors.to_json if errors

            stack_id = stack['stack']['id']

            logger.info 'Checking network stack creation...'
            stack_info, errors = create_stack_wait(popUrls[:orch], pop_auth['tenant_id'], stack_name, tenant_token, 'NS Network')
            return 400, errors.to_json if errors

            logger.info 'Network stack CREATE_COMPLETE. Reading network information from stack...'
            sleep(3)
            network_resources, errors = getStackResources(popUrls[:orch], pop_auth['tenant_id'], stack_name, tenant_token)
            logger.error errors if errors
            return 400, errors.to_json if errors
            stack_networks = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Net' }
            stack_routers = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Router' }

            networks = []
            stack_networks.each do |network|
                net, errors = getStackResource(popUrls[:orch], pop_auth['tenant_id'], stack_name, stack_id, network['resource_name'], tenant_token)
                networks.push(id: net['resource']['attributes']['id'], alias: net['resource']['attributes']['name'])
            end
            routers = []
            stack_routers.each do |router|
                router, errors = getStackResource(popUrls[:orch], pop_auth['tenant_id'], stack_name, stack_id, router['resource_name'], tenant_token)
                routers.push(id: router['resource']['attributes']['id'], alias: router['resource']['attributes']['name'])
            end
            @instance.push(lifecycle_event_history: 'NETWORK CREATED')
            @instance.update_attribute('vlr', networks)

            puts @instance['resource_reservation']
            resource_reservation = []
            resource_reservation << {
                ports: [],
                network_stack: stack,
                routers: routers,
                networks: networks,
                public_network_id: publicNetworkId,
                dns_server: popUrls[:dns],
                pop_id: pop_auth['pop_id']
            }
            @instance.update_attribute('resource_reservation', resource_reservation)
        end

        @instance.update_attribute('status', 'INSTANTIATING VNFs')
        vnfrs = []
        # for each VNF, instantiate
        mapping['vnf_mapping'].each do |vnf|
            logger.info 'Start instantiation process of ' + vnf.to_s
            pop_id = vnf['maps_to_PoP'].gsub('/pop/', '')
            vnf_id = vnf['vnf'].delete('/')
            pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == pop_id }
            popUrls = pop_auth['urls']

            # needs to be migrated to the VNFGFD
            sla_info = slaInfo['constituent_vnf'].find { |cvnf| cvnf['vnf_reference'] == vnf_id }
            if sla_info.nil?
                logger.error 'NO SLA found with the VNF ID that has the NSD.'
                error = { 'info' => 'Error with the VNF ID. NO SLA found with the VNF ID that has the NSD.' }
                recoverState(@instance, error)
            end
            vnf_flavour = sla_info['vnf_flavour_id_reference']
            logger.debug 'VNF Flavour: ' + vnf_flavour

            vnf_provisioning_info = {
                ns_id: nsd['id'],
                vnf_id: vnf_id,
                flavour: vnf_flavour,
                vim_id: pop_id,
                auth: {
                    url: {
                        keystone: popUrls[:keystone],
                        orch: popUrls[:orch]
                    },
                    tenant: pop_auth['tenant_name'],
                    username: pop_auth['username'],
                    token: pop_auth['token'],
                    password: pop_auth['password']
                },
                reserved_resources: @instance['resource_reservation'].find { |resources| resources[:pop_id] == pop_id },
                security_group_id: pop_auth['security_group_id'],
                callback_url: settings.manager + '/ns-instances/' + @instance['id'] + '/instantiate'
            }

            logger.debug vnf_provisioning_info
            @instance.push(lifecycle_event_history: 'INSTANTIATING ' + vnf_id.to_s + ' VNF')
            @instance.update_attribute('instantiation_start_time', DateTime.now.iso8601(3).to_s)

            begin
                response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances', vnf_provisioning_info.to_json, content_type: :json
            rescue => e
                @instance.push(lifecycle_event_history: 'ERROR_CREATING ' + vnf_id.to_s + ' VNF')
                @instance.update_attribute('status', 'ERROR_CREATING')
                logger.error e.response
                if e.response.nil?
                    if e.response.code.nil?
                        logger.error e
                        logger.error 'Response code not defined.'
                    else
                        error = ''
                        if e.response.code == 404
                            error = 'The VNFD is not defined in the VNF Catalogue.'
                            @instance.push(audit_log: error)
                        else
                            if e.response.body.nil?
                                error = 'Instantiation error. Response from the VNF Manager with no information.'
                            else
                                @instance.push(audit_log: e.response.body)
                                error = 'Instantiation error. Response from the VNF Manager: ' + e.response.body
                            end
                        end
                        logger.error error
                        generateMarketplaceResponse(callback_url, generateError(nsd['id'], 'FAILED', error))
                        return
                    end
                end
                logger.error 'Handle error.'
                return
            end

            vnfr, errors = parse_json(response)
            logger.error errors if errors

            vnfrs << {
                vnfd_id: vnfr['vnfd_reference'],
                vnfi_id: [],
                vnfr_id: vnfr['_id'],
                pop_id: pop_id
            }
            @instance.update_attribute('vnfrs', vnfrs)
        end
        logger.info 'Creating VNFs for the NS instance ' + nsd['id'].to_s + '...'
        nil
    end
end
