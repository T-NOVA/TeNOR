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
    # @param [JSON] pop_info Information about the PoP
    # @param [JSON] callback_url Callback url in case of error happens
    # @return [Hash, nil] authentication
    # @return [Hash, String] if the parsed message is an invalid JSON
    def create_authentication(instance, nsd_id, pop_info, callback_url)
        @instance = instance

        logger.info 'Authentication not created for this PoP. Starting creation of credentials.'

        pop_auth = {}
        pop_auth['pop_id'] = pop_info['id'].to_s
        extra_info = pop_info['extra_info']
        popUrls = getPopUrls(extra_info)
        pop_auth['urls'] = popUrls

        # create credentials for pop_id
        if popUrls[:keystone].nil? || popUrls[:orch].nil? #|| popUrls[:tenant].nil?
            return handleError(@instance, 'Internal error: Keystone and/or openstack urls missing.')
        end

        token = ''
        keystone_url = popUrls[:keystone]
        if @instance['project'].nil?
            credentials, errors = authenticate(keystone_url, pop_info['tenant_name'], pop_info['user'], pop_info['password'])
            logger.error errors if errors
            @instance.update_attribute('status', 'ERROR_CREATING') if errors
            @instance.push(audit_log: errors) if errors
            return 400, errors.to_json if errors

            tenant_id = credentials[:tenant_id]
            user_id = credentials[:user_id]
            token = credentials[:token]

            if !pop_info['is_admin']
                  pop_auth['username'] = pop_info['user']
                  pop_auth['tenant_name'] = pop_info['tenant_name']
                  pop_auth['password'] = pop_info['password']
                  pop_auth['tenant_id'] = tenant_id
                  pop_auth['user_id'] = user_id
                  pop_auth['token'] = token
            else
                #generate credentials
                credentials, errors = generate_credentials(@instance, keystone_url, popUrls, tenant_id, user_id, token)
                return 400, errors if errors
                pop_auth = pop_auth.merge(credentials)
=begin
                keystone_version = URI(keystone_url).path.split('/').last
                if keystone_version == 'v2.0'
                    credentials, errors = generate_v2_credentials(@instance, popUrls, tenant_id, user_id, token)
                    return 400, errors if errors
                    pop_auth = pop_auth.merge(credentials)
                elsif keystone_version == 'v3'
                    pop_auth, errors = generate_v3_credentials(@instance, popUrls, tenant_id, user_id, token)
                    return 400, errors if errors
                    pop_auth = pop_auth.merge(credentials)
                end
=end
            end
        end
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
                    orch: popUrls[:orch],# to remove
                    heat: popUrls[:orch],
                    compute: popUrls[:compute]
                },
                tenant_id: pop_auth['tenant_id'],
                token: pop_auth['token'],
				is_admin: pop_auth['is_admin']
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
