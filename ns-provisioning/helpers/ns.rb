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

    # Updates the instance status with the Error message.
    # @param [JSON] instance NSr
    # @param [JSON] error message
    # @return [Integer, Dynamic] the error response
    def handleError(instance, errors)
        @instance = instance
        logger.error errors
        @instance.update_attribute('status', 'ERROR_CREATING') unless @instance.destroyed?
        @instance.push(audit_log: errors) unless @instance.destroyed?
        return 400, errors.to_json if errors
    end

    # Recover the state due to fail during the instatiation or when the instance should be removed
    #
    # @param [JSON] instance NSr
    # @return [Hash, nil] NS
    # @return [Hash, String] if the parsed message is an invalid JSON
    def recoverState(instance, pops_auth, _error)
        logger.info 'Recover state executed.'
        @instance = instance
        @instance.update_attribute('status', 'DELETING')
        callback_url = @instance['notification']
        ns_id = @instance['nsd_id']

        # reserved_resources for the instance
        logger.debug 'Removing reserved resources...'
        @instance['resource_reservation'].each do |resource|
            break if resource['pop_id'].nil?

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == resource['pop_id'] }
            keystone_url = auth_info['urls'][:keystone]

            credentials, errors = authenticate(keystone_url, auth_info['tenant_name'], auth_info['username'], auth_info['password'])
            logger.error errors if errors
            @instance.update_attribute('status', 'ERROR_CREATING') if errors
            @instance.push(audit_log: errors) if errors
            return 400, errors.to_json if errors

            tenant_token = credentials[:token]

            stack_url = resource['network_stack']['stack_url']
            logger.debug 'Removing reserved stack...'
            response, errors = delete_stack_with_wait(stack_url, tenant_token)
            logger.error errors if errors
            return 400, errors if errors
            logger.debug 'Reserved stack removed correctly'
        end

        logger.info 'Removing users and tenants...'
        @instance['authentication'].each do |pop_info|
            logger.debug 'Delete users of PoP: ' + pop_info['pop_id'].to_s

            pop_auth = pops_auth.find { |p| p['id'] == pop_info['pop_id'].to_s }
            next if pop_auth.nil?
            # return 400, "PoP not defined and the users cannot be removed." if pop_auth.nil?
            popUrls = getPopUrls(pop_auth['extra_info'])

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == pop_info['pop_id'] }
            credentials, errors = authenticate(popUrls[:keystone], auth_info['tenant_name'], auth_info['username'], auth_info['password'])
            logger.error errors if errors
            @instance.update_attribute('status', 'ERROR_CREATING') if errors
            @instance.push(audit_log: errors) if errors
            return 400, errors.to_json if errors
            token = credentials[:token]

            unless pop_info['security_group_id'].nil?
                #      deleteSecurityGroup(popUrls[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], tenant_token)
            end

            unless settings.default_tenant && !popUrls[:is_admin]
                logger.debug 'Removing user stack....'
                stack_url = auth_info['stack_url']
                if !auth_info['stack_url'].nil?
                    response, errors = delete_stack_with_wait(auth_info['stack_url'], token)
                    logger.error errors if errors
                    return 400, errors if errors
                    logger.debug 'User and tenant removed correctly.'
                else
                    logger.debug 'No user and tenant to remove.'
                end

            end
            logger.debug 'REMOVED: User ' + auth_info['user_id'].to_s + " and tenant '" + auth_info['tenant_id'].to_s
        end
        logger.debug 'Tenants and users removed correctly.'

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
        mapping_info = instantiation_info['mapping']
        nap_id = instantiation_info['nap_id']
        customer_id = instantiation_info['customer_id']
        infr_repo_url = instantiation_info['infr_repo_url']
        slaInfo = nsd['sla'].find { |sla| sla['sla_key'] == flavour }

        if slaInfo.nil?
            return handleError(@instance, 'Internal error: SLA inconsistency')
        end
        sla_id = nsd['sla'].find { |sla| sla['sla_key'] == flavour }['id']
        logger.debug 'SLA id: ' + sla_id

        if pop_list.size == 1 && mapping_info.empty?
            pop_id = pop_list[0]['id']
            logger.info 'Deploy to PoP id: ' + pop_id.to_s
            mapping = getMappingResponse(nsd, pop_id)
        elsif !mapping_info.empty?
            logger.info 'Calling Mapping algorithm '
            logger.info mapping_info
            if infr_repo_url.nil?
                return handleError(@instance, 'Internal error: Infrastructure Repository not reachable.')
            end

            ms = {
                NS_id: nsd['id'],
                NS_sla: sla_id,
                tenor_api: settings.manager,
                infr_repo_api: infr_repo_url # ,
                # development: true,
                # overcommitting: 'true'
            }
            logger.info ms
            mapping, errors = callMapping(mapping_info, ms)
            if mapping['vnf_mapping']
                mapping, errors = replace_pop_name_by_pop_id(mapping, pop_list)
                return handleError(@instance, errors) if errors
            else
                return handleError(@instance, 'Internal error: Mapping: not enough resources.')
            end
            return handleError(@instance, 'Internal error: Mapping not reachable.') if errors
        end

        @instance.update_attribute('mapping_time', DateTime.now.iso8601(3).to_s)
        @instance.push(lifecycle_event_history: 'MAPPED FOUND')

        @instance['vnfrs'] = []
        # @instance['authentication'] = []

        @instance.update_attribute('status', 'CREATING AUTHENTICATIONS')
        # if mapping of all VNFs are in the same PoP. Create Authentication and network 1 time
        mapping['vnf_mapping'].each do |vnf|
            logger.info 'Start authentication process of ' + vnf.to_s
            pop_id = vnf['maps_to_PoP'].gsub('/pop/', '')
            pop_info = pop_list.find { |p| p['id'] == pop_id.to_i }

            # check if this the authentication info is already created for this pop_id, if created, break the each
            logger.info 'Check if authentication is created for this PoP'
            authentication = @instance['authentication'].find { |auth| auth['pop_id'] == pop_id }
            next unless authentication.nil?
            pop_auth, errors = create_authentication(@instance, pop_info)
            return handleError(@instance, errors) if errors
            # @instance['authentication'] << pop_auth
            @instance.push(authentication: pop_auth)
        end

        logger.info 'Authentication generated'

        # check if @instance['authentication'] has the credentials for each PoP in mapping['vnf_mapping'] ? compare sizes?

        @instance.update_attribute('status', 'CREATING NETWORKS')

        # configure wicm if has defined the ip, the customers and naps id
        if !settings.wicm.nil? && !customer_id.nil? && !nap_id.nil?
            pops = []
            @instance['authentication'].each do |pop|
                pops << pop['pop_id']
            end

            wicm_message = {
                service: {
                    ns_instance_id: @instance['id'].to_s,
                    client_mkt_id: customer_id,
                    nap_mkt_id: nap_id,
                    ce_pe: pops,
                    pe_ce: [pops[0]]
                }
            }
            begin
                response = RestClient.post settings.wicm + '/vnf-connectivity', wicm_message.to_json, content_type: :json, accept: :json
            rescue Errno::ECONNREFUSED
                error = { 'info' => 'WICM unreachable.' }
                return handleError(@instance, error)
            rescue => e
                logger.error e
                logger.error e.response
                error = { 'info' => 'Error with the WICM module.' }
                return handleError(@instance, error)
            end
            provider_info, error = parse_json(response)
            return handleError(@instance, errors) if errors

            # for each PoP, send the template
            resource_reservation = []
            @instance['authentication'].each do |auth|
                logger.info 'WICM in POP  ' + auth['pop_id']
                pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == auth['pop_id'] }
                pop_urls = pop_auth['urls']

                ce_transport = provider_info['allocated']['ce_pe'].find { |p| p['nfvi_id'] == auth['pop_id'] }
                pe_transport = provider_info['allocated']['pe_ce'].find { |p| p['nfvi_id'] == auth['pop_id'] }
                wicm_service_request = {
                    physical_network: 'sfcvlan',
                    allocated: {
                        nfvi_id: 'nfvi1',
                        ns_instance_id: 'service1',
                        ce_transport: ce_transport,
                        pe_transport: pe_transport
                    }
                }

                # Request HOT Generator to build the WICM - SFC integration
                hot_template, errors = generateWicmHotTemplate(provider_info)

                logger.info 'Send WICM template to HEAT Orchestration'
                stack_name = 'WICM_SFC_' + @instance['id'].to_s
                template = { stack_name: stack_name, template: hot_template }
                stack, errors = sendStack(pop_urls[:orch], vnf_info['tenant_id'], template, tenant_token)
                return handleError(@instance, errors) if errors

                # Wait for the WICM - SFC provisioning to finish
                stack_info, errors = create_stack_wait(pop_urls[:orch], vnf_info['tenant_id'], stack_name, tenant_token, 'NS WICM')
                return handleError(@instance, errors) if errors

                resource_reservation = @instance['resource_reservation']
                resource_reservation << { wicm_stack: stack, pop_id: pop_auth['pop_id'] }
                @instance.update_attribute('resource_reservation', resource_reservation)
            end
        end

        @instance['authentication'].each do |pop_auth|
            logger.debug 'Generate networks for eah pop'

            tenant_token = pop_auth['token']
            pop_urls = pop_auth['urls']

            publicNetworkId, errors = publicNetworkId(pop_urls[:neutron], tenant_token)
            return handleError(@instance, errors) if errors

            hot_generator_message = {
                nsr_id: @instance['id'],
                nsd: nsd,
                public_net_id: publicNetworkId,
                dns_server: pop_urls[:dns]
            }
            logger.debug 'Generating network HOT template...'
            hot, errors = generateNetworkHotTemplate(sla_id, hot_generator_message)
            return handleError(@instance, errors) if errors

            logger.debug 'Sending network template to HEAT Orchestration'
            stack_name = 'network_' + @instance['id'].to_s
            template = { stack_name: stack_name, template: hot }
            stack, errors = sendStack(pop_urls[:orch], pop_auth['tenant_id'], template, tenant_token)
            return handleError(@instance, errors) if errors

            stack_id = stack['stack']['id']

            # save stack_url in reserved resurces
            logger.debug 'Saving reserved stack....'
            @resource_reservation = @instance['resource_reservation']
            resource_reservation = []
            resource_reservation << {
                ports: [],
                network_stack: { id: stack_id, stack_url: stack['stack']['links'][0]['href'] },
                public_network_id: publicNetworkId,
                dns_server: pop_urls[:dns],
                pop_id: pop_auth['pop_id'],
                routers: [],
                networks: []
            }
            @instance.push(resource_reservation: resource_reservation)

            logger.debug 'Checking network stack creation...'
            stack_info, errors = create_stack_wait(pop_urls[:orch], pop_auth['tenant_id'], stack_name, tenant_token, 'NS Network')
            return handleError(@instance, errors) if errors

            logger.debug 'Network stack CREATE_COMPLETE. Reading network information from stack...'
            sleep(3)
            network_resources, errors = getStackResources(pop_urls[:orch], pop_auth['tenant_id'], stack_name, tenant_token)
            return handleError(@instance, errors) if errors

            stack_networks = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Net' }
            stack_routers = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Router' }

            networks = []
            stack_networks.each do |network|
                net, errors = getStackResource(pop_urls[:orch], pop_auth['tenant_id'], stack_name, stack_id, network['resource_name'], tenant_token)
                # networks.push(id: net['resource']['attributes']['id'], alias: net['resource']['attributes']['name'])
                networks.push(id: net['resource']['physical_resource_id'], alias: net['resource']['physical_resource_id'])
            end
            routers = []
            stack_routers.each do |router|
                router, errors = getStackResource(pop_urls[:orch], pop_auth['tenant_id'], stack_name, stack_id, router['resource_name'], tenant_token)
                # routers.push(id: router['resource']['attributes']['id'], alias: router['resource']['attributes']['name'])
                routers.push(id: router['resource']['physical_resource_id'], alias: router['resource']['physical_resource_id'])
            end
            @instance.push(lifecycle_event_history: 'NETWORK CREATED')
            @instance.update_attribute('vlr', networks)

            # get array
            object = @resource_reservation.find { |s| s[:network_stack][:id] == stack['stack']['id'] }
            # remove array
            @instance.pull(resource_reservation: object)
            # add array
            resource_reservation = resource_reservation.find { |s| s[:network_stack][:id] == stack['stack']['id'] }
            resource_reservation[:routers] = routers
            resource_reservation[:networks] = networks
            @instance.push(resource_reservation: resource_reservation)
        end

        # instantiate each VNF
        @instance.update_attribute('status', 'INSTANTIATING VNFs')
        vnfrs = []
        mapping['vnf_mapping'].each do |vnf|
            response, errors = instantiate_vnf(@instance, nsd['id'], vnf, slaInfo)
            return handleError(@instance, errors) if errors

            vnfrs << {
                vnfd_id: response['vnfd_reference'],
                vnfi_id: [],
                vnfr_id: response['_id'],
                pop_id: response['pop_id']
            }
            @instance.update_attribute('vnfrs', vnfrs)
        end
        logger.info 'Creating VNFs for the NS instance ' + nsd['id'].to_s + '...'
        nil
    end
end
