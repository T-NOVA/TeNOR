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
        logger.debug message.inspect
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
        logger.error "#{@instance['id']}: #{errors}"
        @instance.update_attribute('status', 'ERROR_CREATING') unless @instance.destroyed?
        @instance.push(audit_log: errors) unless @instance.destroyed?
        return 400, errors.to_json if errors
    end

    # Updates the instance status with the Error message when removing
    # @param [JSON] instance NSr
    # @param [JSON] error message
    # @return [Integer, Dynamic] the error response
    def errorDeleting(instance, errors)
        @instance = instance
        logger.error "#{@instance['id']}: #{errors}"
        @instance.update_attribute('status', 'ERROR_DELETING') if errors
        @instance.push(audit_log: errors) if errors
        return 400, errors.to_json if errors
    end

    # Recover the state due to fail during the instatiation or when the instance should be removed
    #
    # @param [JSON] instance NSr
    # @return [Hash, nil] NS
    # @return [Hash, String] if the parsed message is an invalid JSON
    def recoverState(instance, pops_auth, _error)
        @instance = instance
        callback_url = @instance['notification']
        ns_id = @instance['nsd_id']

        # reserved_resources for the instance
        logger.debug 'Removing reserved resources...'
        @instance['authentication'].each do |pop_info|
            logger.debug 'Delete WICM if exists: ' + pop_info['pop_id'].to_s
            if !pop_info['urls']['wicm_ip'].nil?
                logger.debug "Removing VNF Connectivity in WICM..."
                begin
                    RestClient.delete pop_info['urls']['wicm_ip'] + '/vnf-connectivity/' + @instance['id']
                rescue => e
                    logger.error e
                end
            end
        end

        @instance['resource_reservation'].each do |resource|
            break if resource['pop_id'].nil?

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == resource['pop_id'] }
            keystone_url = auth_info['urls'][:keystone]

            credentials, errors = authenticate(keystone_url, auth_info['tenant_name'], auth_info['username'], auth_info['password'])
            return errorDeleting(@instance, errors) if errors
            if !resource['netfloc_stack'].nil?
                stack_url = resource['netfloc_stack']['stack_url']
            elsif !resource['network_stack'].nil?
                stack_url = resource['network_stack']['stack_url']
            else
                next
            end
            logger.debug 'Removing reserved stack...'
            response, errors = delete_stack_with_wait(@instance['id'], stack_url, credentials[:token])
            return errorDeleting(@instance, errors) if errors
            logger.debug 'Reserved stack removed correctly'
        end

        logger.info 'Removing users and tenants...'
        @instance['authentication'].each do |pop_info|
            logger.debug 'Delete users of PoP: ' + pop_info['pop_id'].to_s

            pop_auth = pops_auth.find { |p| p['id'] == pop_info['pop_id'].to_s }
            next if pop_auth.nil?
            pop_info = getPoPExtraInfo(pop_auth['extra_info'])

            auth_info = @instance['authentication'].find { |auth| auth['pop_id'] == pop_info['pop_id'] }
            credentials, errors = authenticate(pop_info[:keystone], auth_info['tenant_name'], auth_info['username'], auth_info['password'])
            return errorDeleting(@instance, errors) if errors

            unless pop_info['security_group_id'].nil?
                #      deleteSecurityGroup(pop_info[:compute], vnf_info['tenant_id'], vnf_info['security_group_id'], credentials[:token])
            end

            unless settings.default_tenant && !pop_info[:is_admin]
                logger.debug 'Removing user stack....'
                stack_url = auth_info['stack_url']
                if !auth_info['stack_url'].nil?
                    response, errors = delete_stack_with_wait(@instance['id'], auth_info['stack_url'], credentials[:token])
                    return errorDeleting(@instance, errors) if errors
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
        sla_info = nsd['sla'].find { |sla| sla['sla_key'] == flavour }

        return handleError(@instance, 'Internal error: SLA inconsistency') if sla_info.nil?
        sla_id = nsd['sla'].find { |sla| sla['sla_key'] == flavour }['id']
        logger.debug "Instantiation request for NSD #{nsd['id']} with SLA id : #{sla_id}"

        if pop_list.size == 1 && mapping_info.empty? && instantiation_info['vnf_mapping'].nil?
            pop_id = pop_list[0]['id']
            logger.debug "Deploy #{@instance['id'].to_s} to PoP id: #{pop_id.to_s}"
            mapping = getMappingResponse(nsd, pop_id)
        elsif !instantiation_info['vnf_mapping'].nil?
            mapping = getMappingResponseWithPops(instantiation_info['vnf_mapping'])
            logger.debug ""
        elsif !mapping_info.nil?
            logger.info 'Calling Mapping algorithm ' + mapping_info.to_s
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
        @instance.update_attribute('status', 'CREATING AUTHENTICATIONS')

        # if mapping of all VNFs are in the same PoP. Create Authentication and network 1 time
        mapping['vnf_mapping'].each do |vnf|
            logger.info "#{@instance['id'].to_s}: Start authentication process of #{vnf.to_s}"
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

        logger.info "#{@instance['id'].to_s}: Authentication generated"

        # check if @instance['authentication'] has the credentials for each PoP in mapping['vnf_mapping'] ? compare sizes?

        @instance.update_attribute('status', 'CREATING NETWORKS')

        # configure wicm if has defined the ip, the customers and naps id
        if !customer_id.nil? && !nap_id.nil?
            logger.debug "#{@instance['id'].to_s}: Creating WICM connectivity..."

            pops = []
            wicm_ip = ""
            @instance['authentication'].each do |pop|
                pops << pop['urls']['wicm_id']
                wicm_ip = pop['urls']['wicm_ip']
            end

            wicm_message = {
                service: {
                    ns_instance_id: @instance['id'].to_s,
                    client_mkt_id: customer_id,
                    nap_mkt_id: nap_id,
                    ce_pe: pops,
                    pe_ce: pops
                }
            }
            begin
                response = RestClient.post wicm_ip + '/vnf-connectivity', wicm_message.to_json, content_type: :json, accept: :json
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

            logger.debug provider_info
            #resource_reservation = @instance['resource_reservation']
            #resource_reservation << { nap_id: nap_id }
            #@instance.push(resource_reservation: { nap_id: nap_id })
            #@instance.update_attribute('resource_reservation', resource_reservation)

            # for each PoP, send the template
            resource_reservation = []
            @instance['authentication'].each do |auth|
                logger.info "#{@instance['id'].to_s}: WICM in POP #{auth['pop_id']}"
                pop_auth = @instance['authentication'].find { |pop| pop['pop_id'] == auth['pop_id'] }
                pop_urls = pop_auth['urls']

                ce_transport = provider_info['allocated']['ce_pe'].find { |p| p['nfvi_id'] == pop_urls['wicm_id'] }
                pe_transport = provider_info['allocated']['pe_ce'].find { |p| p['nfvi_id'] == pop_urls['wicm_id'] }
                next if ce_transport.nil? || pe_transport.nil?
                wicm_service_request = {
                    physical_network: 'sfcvlan',
                    allocated: {
                        nfvi_id: pop_urls['wicm_id'],
                        ns_instance_id: 'service1',
                        ce_transport: ce_transport['transport'],
                        pe_transport: pe_transport['transport']
                    }
                }

                # Request HOT Generator to build the WICM - SFC integration
                hot_template, errors = generateWicmHotTemplate(wicm_service_request)
                return handleError(@instance, errors) if errors

                logger.info 'Send WICM template to HEAT Orchestration'
                stack_name = 'WICM_SFC_' + @instance['id'].to_s
                template = { stack_name: stack_name, template: hot_template }
                stack, errors = sendStack(pop_urls['heat'], pop_auth['tenant_id'], template, pop_auth['token'])
                return handleError(@instance, errors) if errors

                # Wait for the WICM - SFC provisioning to finish
                stack_info, errors = create_stack_wait(pop_urls['heat'], pop_auth['tenant_id'], stack_name, pop_auth['token'], 'NS WICM')
                return handleError(@instance, errors) if errors

                resource_reservation = @instance['resource_reservation']
                resource_reservation << { wicm_stack: stack, pop_id: pop_auth['pop_id'] }
                @instance.update_attribute('resource_reservation', resource_reservation)
            end
        end

        @instance['authentication'].each do |pop_auth|
            logger.debug "#{@instance['id'].to_s}: Generate networks for each pop"

            tenant_token = pop_auth['token']
            pop_urls = pop_auth['urls']

            public_network_id, errors = publicNetworkId(pop_urls['neutron'], tenant_token)
            return handleError(@instance, errors) if errors

            hot_generator_message = {
                nsr_id: @instance['id'],
                nsd: nsd,
                public_net_id: public_network_id,
                dns_server: pop_urls['dns']
            }

            hot, errors = generateNetworkHotTemplate(sla_id, hot_generator_message)
            return handleError(@instance, errors) if errors

            logger.debug "#{@instance['id'].to_s}: Sending network template to HEAT Orchestration"
            stack_name = 'network_' + @instance['id'].to_s
            template = { stack_name: stack_name, template: hot }
            stack, errors = sendStack(pop_urls['heat'], pop_auth['tenant_id'], template, tenant_token)
            return handleError(@instance, errors) if errors

            stack_id = stack['stack']['id']

            logger.debug "#{@instance['id'].to_s}: Saving reserved stack...."
            @resource_reservation = @instance['resource_reservation']
            resource_reservation = []
            resource_reservation << {
                ports: [],
                network_stack: { id: stack_id, stack_url: stack['stack']['links'][0]['href'] },
                public_network_id: public_network_id,
                dns_server: pop_urls['dns'],
                pop_id: pop_auth['pop_id'],
                routers: [],
                networks: [],
                netfloc: {}
            }
            @instance.push(resource_reservation: resource_reservation)

            stack_info, errors = create_stack_wait(pop_urls['heat'], pop_auth['tenant_id'], stack_name, tenant_token, 'NS Network')
            return handleError(@instance, errors) if errors

            logger.debug "#{@instance['id'].to_s}: Network stack CREATE_COMPLETE. Reading network information from stack..."
            sleep(3)
            network_resources, errors = getStackResources(pop_urls['heat'], pop_auth['tenant_id'], stack_name, tenant_token)
            return handleError(@instance, errors) if errors

            stack_networks = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Net' }
            stack_routers = network_resources['resources'].find_all { |res| res['resource_type'] == 'OS::Neutron::Router' }

            networks = []
            stack_networks.each do |network|
                net, errors = getStackResource(pop_urls['heat'], pop_auth['tenant_id'], stack_name, stack_id, network['resource_name'], tenant_token)
                networks.push(id: net['resource']['physical_resource_id'], alias: net['resource']['physical_resource_id'])
            end
            routers = []
            stack_routers.each do |router|
                router, errors = getStackResource(pop_urls['heat'], pop_auth['tenant_id'], stack_name, stack_id, router['resource_name'], tenant_token)
                routers.push(id: router['resource']['physical_resource_id'], alias: router['resource']['physical_resource_id'])
            end
            @instance.push(lifecycle_event_history: 'NETWORK CREATED')
            @instance.update_attribute('vlr', networks)

            #update resource reservation array
            object = @resource_reservation.find { |s| s[:network_stack][:id] == stack['stack']['id'] }
            @instance.pull(resource_reservation: object)
            resource_reservation = resource_reservation.find { |s| s[:network_stack][:id] == stack['stack']['id'] }
            resource_reservation[:routers] = routers
            resource_reservation[:networks] = networks
            @instance.push(resource_reservation: resource_reservation)
        end

        # instantiate each VNF
        @instance.update_attribute('status', 'INSTANTIATING VNFs')
        vnfrs = []
        mapping['vnf_mapping'].each do |vnf|
            response, errors = instantiate_vnf(@instance, nsd['id'], vnf, sla_info)
            return handleError(@instance, errors) if errors

            vnfrs << {
                vnfd_id: response['vnfd_reference'],
                vnfi_id: [],
                vnfr_id: response['_id'],
                pop_id: response['pop_id']
            }
            @instance.update_attribute('vnfrs', vnfrs)
        end
        logger.info "#{@instance['id'].to_s}: Creating VNFs for the NS instance #{nsd['id'].to_s}..."
        nil
    end
end
