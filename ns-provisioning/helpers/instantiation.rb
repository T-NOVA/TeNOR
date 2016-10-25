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
# @see NSProvisioner
module InstantiationHelper

    # Create an authentication to PoP_id
    #
    # @param [JSON] instance NSR instance
    # @param [JSON] nsd_id NSD id
    # @param [JSON] vnf VNF information to deploy
    # @param [JSON] pop_id PoP id
    # @param [JSON] callback_url Callback url in case of error happens
    # @return [Hash, nil] authentication
    # @return [Hash, String] if the parsed message is an invalid JSON
    def create_authentication(instance, nsd_id, vnf, pop_id, callback_url)
        @instance = instance

        logger.info 'Authentication not created for this PoP. Starting creation of credentials.'

        pop_auth = {}
        pop_auth['pop_id'] = pop_id
        popInfo, errors = getPopInfo(pop_id)
        logger.error errors if errors
        generateMarketplaceResponse(callback_url, generateError(nsd_id, 'FAILED', 'Internal error: error getting pop information.')) if errors
        return 400, errors.to_json if errors

        extra_info = popInfo['info'][0]['extrainfo']
        popUrls = getPopUrls(extra_info)
        pop_auth['urls'] = popUrls

        # create credentials for pop_id
        if popUrls[:keystone].nil? || popUrls[:orch].nil? || popUrls[:tenant].nil?
            generateMarketplaceResponse(callback_url, generateError(nsd_id, 'FAILED', 'Internal error: Keystone and/or openstack urls missing.'))
            return
        end

        token = ''
        if @instance['project'].nil?
            keystone_version = URI(popUrls[:keystone]).path.split('/').last

            if keystone_version == 'v2.0'
                user_authentication, errors = authentication_v2(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
                logger.error errors if errors
                @instance.update_attribute('status', 'ERROR_CREATING') if errors
                @instance.push(audit_log: errors) if errors
                return 400, errors.to_json if errors
                tenant_id = user_authentication['access']['token']['tenant']['id']
                user_id = user_authentication['access']['user']['id']
                token = user_authentication['access']['token']['id']
            elsif keystone_version == 'v3'
                puts popUrls[:tenant]
                puts popInfo['info'][0]['adminuser']
                user_authentication, errors = authentication_v3(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
                logger.error errors if errors
                @instance.update_attribute('status', 'ERROR_CREATING') if errors
                @instance.push(audit_log: errors) if errors
                return 400, errors.to_json if errors
                if user_authentication['token']['project'].nil?
                    tenant_id = user_authentication['token']['project']['id']
                    user_id = user_authentication['token']['user']['id']
                    token = user_authentication['token']['id']
                else
                    errors = "No project found with the authentication."
                    @instance.update_attribute('status', 'ERROR_CREATING') if errors
                    @instance.push(audit_log: errors) if errors
                    return 400, errors.to_json if errors
                end
            end

            if !popUrls[:is_admin]
                  pop_auth['username'] = popInfo['info'][0]['adminuser']
                  pop_auth['tenant_name'] = popUrls[:tenant]
                  pop_auth['password'] = popInfo['info'][0]['password']
                  pop_auth['tenant_id'] = tenant_id
                  pop_auth['user_id'] = user_id
                  pop_auth['token'] = token
            else
                if keystone_version == 'v2.0'
                    pop_auth = generate_v2_credentials(popInfo, popUrls, tenant_id, user_id, token)
                    pop_auth['urls'] = popUrls
                elsif keystone_version == 'v3'
                    pop_auth = generate_v3_credentials(popInfo, popUrls, tenant_id, user_id, token)
                    pop_auth['urls'] = popUrls
                end
            end
        end
            #pop_auth
=begin
            begin
                logger.info 'Authentication using new user credentials.'
                puts pop_auth['tenant_id']
                puts pop_auth['username']
                puts pop_auth['password']
                pop_auth['token'] = openstackAuthentication(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'])
                puts pop_auth['token']
                if pop_auth['token'].nil?
                    error = 'Authentication failed.'
                    logger.error error
                    @instance.push(audit_log: errors) if errors
                    @instance.update_attribute('status', 'ERROR_CREATING')
                    return 400, error.to_json
                end

                logger.info 'Configuring Security Groups'
                pop_auth['security_group_id'] = configureSecurityGroups(popUrls[:compute], pop_auth['tenant_id'], pop_auth['token'])

                logger.info 'Tenant id: ' + pop_auth['tenant_id']
                logger.info 'Username: ' + pop_auth['username']
            rescue => e
                logger.error e
                error = { 'info' => 'Error creating the Openstack credentials.' }
                logger.error error
                recoverState(@instance, error)
                return 400, error


            begin
                if keystone_version == 'v2.0'
                    user_authentication, errors = openstackUserAuthentication(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
                elsif keystone_version == 'v3'
                    user_authentication, errors = authentication_v3(popUrls[:keystone], popUrls[:tenant], popInfo['info'][0]['adminuser'], popInfo['info'][0]['password'])
                end
                logger.error errors if errors
                @instance.update_attribute('status', 'ERROR_CREATING') if errors
                @instance.push(audit_log: errors) if errors
                return 400, errors.to_json if errors

                if keystone_version == 'v2.0'
                    tenant_id = user_authentication['access']['token']['tenant']['id']
                    user_id = user_authentication['access']['user']['id']
                    token = user_authentication['access']['token']['id']
                elsif keystone_version == 'v3'
                    tenant_id = user_authentication['token']['project']['id']
                    user_id = user_authentication['token']['user']['id']
                    token = user_authentication['token']['id']
                end

                if !popUrls[:is_admin]
                    pop_auth['username'] = popInfo['info'][0]['adminuser']
                    pop_auth['tenant_name'] = popUrls[:tenant]
                    pop_auth['password'] = popInfo['info'][0]['password']
                    pop_auth['tenant_id'] = tenant_id
                    pop_auth['user_id'] = user_id
                else
                    if settings.default_tenant
                        pop_auth['username'] = settings.default_user_name
                        pop_auth['tenant_name'] = settings.default_tenant_name
                        pop_auth['tenant_id'] = getTenantId(popUrls[:keystone], pop_auth['tenant_name'], token)
                        pop_auth['user_id'] = getUserId(popUrls[:keystone], pop_auth['username'], token)
                        pop_auth['password'] = 'secretsecret'

                        if pop_auth['tenant_id'].nil? && pop_auth['user_id'].nil?
                            tenant_id, user_id = create_user_and_project(@instance['id'], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'], tenant_id, token)
                            pop_auth['tenant_id'] = tenant_id
                            pop_auth['user_id'] = user_id
                        else
                            pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token) if pop_auth['tenant_id'].nil?
                            if pop_auth['user_id'].nil?
                                pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], tenant_id, token)
                            else
                                if !settings.default_user_password.nil?
                                    pop_auth['password'] = settings.default_user_password
                                end
                            end
                        end
                    else
                        pop_auth['tenant_name'] = generated_credentials['tenant_name']
                        pop_auth['username'] = generated_credentials['username']
                        pop_auth['password'] = generated_credentials['password']
                        tenant_id, user_id = create_user_and_project(@instance['id'], 'tenor_instance_' + @instance['id'].to_s, 'user_' + @instance['id'].to_s, 'secretsecret', tenant_id, token)
                        pop_auth['tenant_id'] = tenant_id
                        pop_auth['user_id'] = user_id

=begin
                        pop_auth['tenant_name'] = 'tenor_instance_' + @instance['id'].to_s
                        pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token)
                        pop_auth['username'] = 'user_' + @instance['id'].to_s
                        pop_auth['password'] = 'secretsecret'
                        pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], token)
=end
=begin
                    end

                    if pop_auth['tenant_id'].nil? || pop_auth['user_id'].nil?
                        error = 'Tenant or user not created.'
                        logger.error error
                        @instance.push(audit_log: errors) if errors
                        @instance.update_attribute('status', 'ERROR_CREATING')
                        return 400, error.to_json
                    end

                    logger.info 'Created user with admin role.'
                    putRoleAdmin(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['user_id'], token)
                end

                logger.info 'Authentication using new user credentials.'
                puts pop_auth['tenant_id']
                puts pop_auth['username']
                puts pop_auth['password']
                pop_auth['token'] = openstackAuthentication(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'])
                puts pop_auth['token']
                if pop_auth['token'].nil?
                    error = 'Authentication failed.'
                    logger.error error
                    @instance.push(audit_log: errors) if errors
                    @instance.update_attribute('status', 'ERROR_CREATING')
                    return 400, error.to_json
                end

                logger.info 'Configuring Security Groups'
                pop_auth['security_group_id'] = configureSecurityGroups(popUrls[:compute], pop_auth['tenant_id'], pop_auth['token'])

                logger.info 'Tenant id: ' + pop_auth['tenant_id']
                logger.info 'Username: ' + pop_auth['username']
            rescue => e
                logger.error e
                error = { 'info' => 'Error creating the Openstack credentials.' }
                logger.error error
                recoverState(@instance, error)
                return 400, error
            end
        end
=end
        pop_auth
    end

    # Instantiate a VNF calling the VNF Manager
    #
    # @param [JSON] instance NSR instance
    # @param [JSON] nsd_id NSD id
    # @param [JSON] vnf VNF information to deploy
    # @param [JSON] slaInfo Sla information
    # @return [Hash, nil] NS
    # @return [Hash, String] if the parsed message is an invalid JSON
    def instantiate_vnf(instance, nsd_id, vnf, slaInfo)
        @instance = instance
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
            ns_id: nsd_id,
            vnf_id: vnf_id,
            flavour: vnf_flavour,
            vim_id: pop_id,
            auth: {
                url: {
                    keystone: popUrls[:keystone],
                    orch: popUrls[:orch],
                    compute: popUrls[:compute]
                },
                tenant: pop_auth['tenant_name'],
                username: pop_auth['username'],
                token: pop_auth['token'],
                password: pop_auth['password'],
                is_admin: pop_auth['is_admin'],
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
=begin        rescue RestClient::ExceptionWithResponse => e
            puts "Excepion with response"
            puts e
            logger.error e
            logger.error e.response
            if !e.response.nil?
                logger.error e.response.body
            end
            #return e.response.code, e.response.body
            logger.error 'Handle error.'
            return
=end
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
                    generateMarketplaceResponse(callback_url, generateError(nsd_id, 'FAILED', error))
                    return 400, error
                end
            end
            logger.error 'Handle error.'
            return 400, "Error wiht the VNF"
        end

        vnf_manager_response, errors = parse_json(response)
        logger.error errors if errors

        vnf_manager_response['pop_id'] = pop_id
        vnf_manager_response
    end
end
