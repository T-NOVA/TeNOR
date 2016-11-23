#
# TeNOR - VNF Provisioning
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
# @see Provisioning
class Provisioning < VnfProvisioning
    # @method get_vnf_provisioning_network_service_ns_id
    # @overload get '/vnf-provisioning/network-service/:ns_id'
    #   Get all the VNFRs of a specific NS
    # Get all the VNFRs of a specific NS
    get '/network-service/:nsr_id' do |nsr_id|
        begin
            vnfrs = Vnfr.where(nsr_instance: nsr_id)
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end
        halt 200, vnfrs.to_json
    end

    # @method get_vnf_provisioning_vnf_instances
    # @overload get '/vnf-provisioning/vnf-instances'
    #   Return all VNF Instances
    # Return all VNF Instances
    get '/vnf-instances' do
        begin
            vnfrs = Vnfr.all
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end
        halt 200, vnfrs.to_json
    end

    # @method post_vnf_provisioning_vnf_instances
    # @overload post '/vnf-provisioning/vnf-instances'
    #   Instantiate a VNF
    #   @param [JSON] the VNF to instantiate and auth info
    # Instantiate a VNF
    post '/vnf-instances' do
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        instantiation_info = parse_json(request.body.read)
        halt 400, 'NS Manager callback URL not found' unless instantiation_info.key?('callback_url')

        vnf = instantiation_info['vnf']

        begin
            vnf_flavour = vnf['vnfd']['deployment_flavours'].find { |dF| dF['flavour_key'] == instantiation_info['flavour'] }['id']
        rescue NoMethodError => e
            halt 400, "Deployment flavour #{instantiation_info['flavour']} not found"
        end

        logger.debug 'Instantiation info: nsd_id -> ' + instantiation_info['ns_id'].to_s + ' Vnf_id -> ' + instantiation_info['vnf_id'].to_s + ' Flavour -> ' + vnf_flavour

        # Verify if the VDU images are accessible to download
        logger.debug 'Verifying VDU images'
        verify_vdu_images(vnf['vnfd']['vdu'])

        # Build the VNFR and store it
        begin
            vnfr = Vnfr.create!(
                deployment_flavour: instantiation_info['flavour'],
                nsr_instance: instantiation_info['nsr_id'],
                vnfd_reference: vnf['vnfd']['id'],
                vim_id: instantiation_info['vim_id'],
                vlr_instances: nil,
                port_instances: nil,
                vnf_addresses: nil,
                vnf_status: 3,
                notifications: [instantiation_info['callback_url']],
                lifecycle_event_history: Array('INIT'),
                audit_log: nil,
                vdu: [],
                stack_url: nil,
                vms_id: nil,
                vms: [],
                scale_info: nil,
                scale_resources: [],
                outputs: [],
                lifecycle_info: vnf['vnfd']['vnf_lifecycle_events'].find { |lifecycle| lifecycle['flavor_id_ref'].casecmp(vnf_flavour.downcase).zero? },
                lifecycle_events_values: nil,
                security_group_id: instantiation_info['security_group_id'],
                public_network_id: instantiation_info['reserved_resources']['public_network_id'],
                resource_stats: []
            )
        rescue Moped::Errors::OperationFailure => e
            return 400, 'ERROR: Duplicated VNF ID' if e.message.include? 'E11000'
            return 400, e.message
        end

        # Convert VNF to HOT (call HOT Generator)
        halt 400, 'No T-NOVA flavour defined.' unless instantiation_info.key?('flavour')

        vim_info = instantiation_info['auth']
        vim_info['keystone'] = vim_info['url']['keystone']
        vim_info['heat'] = vim_info['url']['heat']
        vim_info['compute'] = vim_info['url']['compute']

        logger.debug 'Send VNFD to Hot Generator'
        hot_generator_message = {
            vnf: vnf,
            vnfr_id: vnfr.id,
            security_group_id: instantiation_info['security_group_id'],
            networks_id: instantiation_info['reserved_resources']['networks'],
            routers_id: instantiation_info['reserved_resources']['routers'],
            public_network_id: instantiation_info['reserved_resources']['public_network_id'],
            dns_server: instantiation_info['reserved_resources']['dns_server'],
            flavours: []
        }
        unless vim_info['is_admin']
            flavors = []
            vnf['vnfd']['vdu'].each do |vdu|
                flavour_id, errors = get_vdu_flavour(vdu, vim_info['compute'], vim_info['tenant_id'], vim_info['token'])
                logger.error errors if errors
                if errors == 'Flavor not found.'
                    halt 400, 'No flavours available for the vdu ' + vdu['id'].to_s
                elsif errors == 'Error getting flavours.'
                    halt 400, 'Error getting flavors for vdu ' + vdu['id'].to_s
                end
                halt 400, 'Error getting flavors for vdu ' + vdu['id'].to_s if errors
                flavors << { id: vdu['id'], flavour_id: flavour_id }
            end
            hot_generator_message['flavours'] = flavors
        end

        begin
            hot = parse_json(RestClient.post(settings.hot_generator + '/hot/' + vnf_flavour, hot_generator_message.to_json, content_type: :json, accept: :json))
        rescue Errno::ECONNREFUSED
            halt 500, 'HOT Generator unreachable'
        rescue => e
            logger.error e
            logger.error e.response if e.response
            halt e.response.code, e.response.body if e.response
            halt 500, e
        end

        logger.debug 'HEAT template generated'

        # Request VIM to provision a VNF
        response = provision_vnf(vim_info, vnf['vnfd']['name'].delete(' ') + '_' + vnfr.id, hot)
        logger.debug 'Provision response: ' + response.to_json

        # Update the VNFR
        vnfr.push(lifecycle_event_history: 'CREATE_IN_PROGRESS')

        # save the VNF information into the VNFR
        vdu = []
        vnf['vnfd']['vdu'].each do |v|
            vdu << { id: v['id'], alias: v['alias'] }
        end

        vlrs = []
        vnf['vnfd']['vlinks'].each do |vlink|
            vlrs << { id: vlink['id'], alias: vlink['alias'] }
        end

        ports = []
        vnf['vnfd']['vdu'].each do |vdu|
            vdu['connection_points'].each do |port|
                ports << { id: port['id'], vlink_ref: port['vlink_ref'] }
            end
        end

        vnfr.update_attributes!(
            stack_url: response['stack']['links'][0]['href'],
            vdu: vdu,
            vlr_instances: vlrs,
            port_instances: ports
        )

        #    if vnf['type'] != 'vSA'
        create_thread_to_monitor_stack(vnfr.id, vnfr.stack_url, vim_info, instantiation_info['callback_url'])
        logger.info 'Created thread to monitor stack'
        #    end

        halt 201, vnfr.to_json
    end

    # @method get_vnf_provisioning_vnf_instances_vnfr_id
    # @overload get '/vnf-provisioning/vnf-instances/:vnfr_id
    #   Get a specific VNFR by its ID
    # Get a specific VNFR by its ID
    get '/vnf-instances/:vnfr_id' do |vnfr_id|
        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end
        halt 200, vnfr.to_json
    end

    # @method post_vnf_provisioning_instances_vnfr_id_destroy
    # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/destroy'
    #   Destroy a VNF
    #   @param [String] vnfr_id the VNFR ID
    #   @param [JSON] the VNF to instantiate and auth info
    # Destroy a VNF
    post '/vnf-instances/:vnfr_id/destroy' do |vnfr_id|
        logger.info 'Start removing process for VNFR: ' + vnfr_id.to_s
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        destroy_info = parse_json(request.body.read)
        logger.debug 'Destroy info: ' + destroy_info.to_json

        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end

        # Request an auth token from the VIM
        vim_info = destroy_info['auth']
        vim_info['keystone'] = vim_info['url']['keystone']
        callback_url = destroy_info['callback_url']

        # if the stack contains nested templates, remove nesed before
        vnfr['scale_resources'].each do |resource|
            stack_url = resource['stack_url']
            logger.info 'Sending request to Openstack for Remove scaled resource'
            response, errors = delete_stack_with_wait(stack_url, vim_info['token'])
            vnfr.pull(scale_resources: resource)
            logger.info 'Removed scaled resources.'
        end

        # Requests the VIM to delete the stack
        response, errors = delete_stack_with_wait(vnfr.stack_url, vim_info['token'])
        logger.error errors if errors
        if response == 400
            halt 400, errors if errors
        end

        logger.debug 'VIM response to destroy: ' + response.to_json

        if settings.mapi.nil?
            logger.info 'mAPI not defined. No action performed to mAPI.'
        else
            # Delete the VNFR from mAPI
            logger.info 'Sending delete command to mAPI...'
            logger.debug 'VNFR: ' + vnfr_id
            sendDeleteCommandToMAPI(vnfr_id)
        end

        logger.info 'Removing the VNFR from the database...'
        vnfr.destroy
        halt 200 # , response.body
    end

    # @method post_vnf_provisioning_instances_id_config
    # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/config'
    #   Request to execute a lifecycle event
    #   @param [String] vnfr_id the VNFR ID
    #   @param [JSON]
    # Request to execute a lifecycle event
    put '/vnf-instances/:vnfr_id/config' do |vnfr_id|
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        config_info = parse_json(request.body.read)

        # Return if have an invalid event type
        halt 400, 'Invalid event type.' unless ['start', 'stop', 'restart', 'scale-in', 'scale-out'].include? config_info['event'].downcase

        # Get VNFR stack info
        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end

        # Return if event doesn't have information
        halt 400, 'Event has no information' if vnfr.lifecycle_info['events'][config_info['event']].nil?

        halt 400, 'mAPI not defined. No execution performed.' if settings.mapi.nil?

        # Build mAPI request
        mapi_request = {
            event: config_info['event'],
            vnf_controller: vnfr.vnf_addresses['controller'],
            parameters: vnfr.lifecycle_events_values[config_info['event']]
        }
        logger.debug 'mAPI request: ' + mapi_request.to_json
        # Send request to the mAPI
        code, body = sendCommandToMAPI(vnfr_id, mapi_request) unless settings.mapi.nil?

        # Update the VNFR event history
        vnfr.push(lifecycle_event_history: "Executed a #{mapi_request[:event]}")

        halt 200
    end

    # @method post_vnf_provisioning_id_stack_status
    # @overload post '/vnf-provisioning/:vnfr_id/stack/:status'
    #   Receive a VNF status after provisioning at the VIM
    #   @param [String] vnfr_id the VNFR ID
    #   @param [String] status the VNF status at the VIM
    # Receive a VNF status after provisioning at the VIM
    post '/:vnfr_id/stack/:status' do
        # Parse body message
        stack_info = parse_json(request.body.read)
        logger.debug 'Stack info: ' + stack_info.to_json
        auth_token = stack_info['vim_info']['token']

        begin
            vnfr = Vnfr.find(params[:vnfr_id])
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'VNFR record not found'
            halt 404
        end

        # If stack is in create complete state
        if params[:status] == 'create_complete'
            logger.info 'Create complete'

            vms = []
            vms_id = {}
            # get stack resources
            resources, errors = getStackResources(vnfr.stack_url, auth_token)
            logger.error errors if errors
            logger.info resources
            resources.each do |resource|
                # map ports to openstack_port_id
                unless vnfr.port_instances.detect { |port| resource['resource_name'] == port['id'] }.nil?
                    vnfr.port_instances.find { |port| resource['resource_name'] == port['id'] }['physical_resource_id'] = resource['physical_resource_id']
                end
                unless vnfr.vlr_instances.detect { |vlink| resource['resource_name'] == vlink['id'] }.nil?
                    vnfr.vlr_instances.find { |vlink| resource['resource_name'] == vlink['id'] }['physical_resource_id'] = resource['physical_resource_id']
                end
                unless resource['resource_type'] != 'OS::Heat::AutoScalingGroup'
                    stack_url = resource['links'].find { |link| link['rel'] == 'nested' }['href']
                    nested_resources = getStackResources(stack_url, auth_token)
                    logger.info 'VIM response of AutoScalingGroup: ' + nested_resources.to_json
                    logger.info resource['links']
                    # scale_resources << {:vdu => output['output_key'].match(/^(.*)#scale_in_url/i)[1], :scale_in => output['output_value']}
                    # scale_resources << {:id => output['output_value']}
                end
                unless resource['resource_type'] != 'OS::Nova::Server'
                    vm = vms.find { |vdu| vdu[:id] == resource['resource_name'] }
                    if vm.nil?
                        vms << { id: resource['resource_name'], physical_resource_id: resource['physical_resource_id'] }
                    else
                        vm[:id] = resource['resource_name']
                        vm[:physical_resource_id] = resource['physical_resource_id']
                    end
                end
                unless resource['resource_type'] != 'OS::Nova::Flavor'
                    resource['required_by'].each do |vdu|
                        vm = vms.find { |vm| vm[:id] == vdu }
                        if vm.nil?
                            vms << { id: vdu, flavour_id: resource['physical_resource_id'] }
                        else
                            vm[:flavour_id] = resource['physical_resource_id']
                        end
                    end
                end
                next if resource['resource_type'] != 'OS::Glance::Image'
                resource['required_by'].each do |vdu|
                    vm = vms.find { |vm| vm[:id] == vdu }
                    if vm.nil?
                        vms << { id: vdu, image_id: resource['physical_resource_id'] }
                    else
                        vm[:image_id] = resource['physical_resource_id']
                    end
                end
            end

            outputs = []
            stack_info['stack']['outputs'].select do |output|
                outputs << { key: output['output_key'], value: output['output_value'] }
            end

            # update vnfr with the key generated in the stack
            private_key = outputs.find { |res| res[:key] == 'private_key' }
            lifecycle_events_values = {}
            vnf_addresses = {}
            scale_urls = {}
            # auto_scale_resources = []
            stack_info['stack']['outputs'].select do |output|
                if output['output_key'] == 'private_key'
                    private_key = output['output_value']
                elsif output['output_key'] =~ /^.*#id$/i
                    vms_id[output['output_key'].match(/^(.*)#id$/i)[1]] = output['output_value']
                else
                    if output['output_key'] =~ /^.*#PublicIp$/i
                        #            vnf_addresses['controller'] = output['output_value']
                    end

                    # other parameters
                    vnfr.lifecycle_info['events'].each do |event, event_info|
                        next if event_info.nil?
                        JSON.parse(event_info['template_file']).each do |id, parameter|
                            # logger.debug parameter
                            parameter_match = parameter.delete(' ').match(/^get_attr\[(.*)\]$/i).to_a
                            string = parameter_match[1].split(',').map(&:strip)
                            key_string = string.join('#')
                            # logger.debug 'Key string: ' + key_string.to_s + '. Out_key: ' + output['output_key'].to_s
                            if string[1] == 'PublicIp' # DEPRECATED: to be removed when all VNF developers uses the new form
                                vnf_addresses[output['output_key']] = output['output_value']
                                lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                                lifecycle_events_values[event][key_string] = output['output_value']
                            elsif string[2] == 'PublicIp'
                                if key_string == output['output_key']
                                    if id == 'controller'
                                        vnf_addresses['controller'] = output['output_value']
                                    end
                                    vnf_addresses[output['output_key']] = output['output_value']
                                    lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                                    lifecycle_events_values[event][key_string] = output['output_value']
                                end
                            elsif string[1] == 'fixed_ips' # PrivateIp
                                key_string2 = output['output_key'].partition('#')[2]
                                if key_string2 == key_string
                                    vnf_addresses[output['output_key']] = output['output_value']
                                    lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                                    if output['output_value'].is_a?(Array)
                                        lifecycle_events_values[event][key_string] = output['output_value'][0]
                                    else
                                        lifecycle_events_values[event][key_string] = output['output_value']
                                    end
                                end
                            elsif output['output_key'] =~ /^#{parameter_match[1]}##{parameter_match[2]}$/i
                                vnf_addresses[(parameter_match[1]).to_s] = output['output_value'] if parameter_match[2] == 'ip' && !vnf_addresses.key?((parameter_match[1]).to_s) # Only to populate VNF
                                lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                                lifecycle_events_values[event]["#{parameter_match[1]}##{parameter_match[2]}"] = output['output_value']
                            elsif output['output_key'] == id # 'controller'
                                lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                                lifecycle_events_values[event][key_string] = output['output_value']
                            end
                        end
                    end
                end
            end
            logger.debug 'VMs ID: ' + vms_id.to_json
            logger.debug 'VNF Addresses: ' + vnf_addresses.to_json
            logger.debug 'Lifecycle events values: ' + lifecycle_events_values.to_json

            # Update the VNFR
            vnfr.push(lifecycle_event_history: stack_info['stack']['stack_status'])
            vnfr.update_attributes!(
                vnf_addresses: vnf_addresses,
                vnf_status: 1,
                vms_id: vms_id,
                vms: vms,
                lifecycle_events_values: lifecycle_events_values,
                scale_info: scale_urls # ,
                # scale_resources: scale_resources
            )

            if vnfr.lifecycle_info['authentication_type'] == 'PubKeyAuthentication'
                if vnfr.lifecycle_info['authentication'] == ''
                    logger.info 'Public Authentication is empty. Included the key generated by Openstack.'
                    vnfr.lifecycle_info["authentication"] = private_key
                    vnfr.update_attributes!(lifecycle_info["authentication"] = private_key)
                end
            end

            logger.info 'Registring values to mAPI if required...'
            # Send the VNFR to the mAPI
            registerRequestToMAPI(vnfr) unless settings.mapi.nil?

            # Build message to send to the NS Manager callback
            vnfi_id = []
            vnfr.vms_id.each { |_key, value| vnfi_id << value }
            message = { vnfd_id: vnfr.vnfd_reference, vnfi_id: vnfi_id, vnfr_id: vnfr.id, vnf_addresses: vnf_addresses, stack_resources: vnfr }
            nsmanager_callback(stack_info['ns_manager_callback'], message)

            Thread.new do
                resource_stats = []
                events, errors = getStackEvents(vnfr.stack_url, auth_token)
                resource_stats = calculate_event_time(resources, events)
                vnfr.update_attributes!(resource_stats: resource_stats)
            end
        else
            # If the stack has failed to create
            if params[:status] == 'create_failed'
                logger.debug 'Created failed'

                # Request VIM information about the error
                begin
                    response = JSON.parse(RestClient.get(vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json))
                rescue Errno::ECONNREFUSED
                    halt 500, 'VIM unreachable'
                rescue => e
                    logger.error e.response
                    halt e.response.code, e.response.body
                end
                puts response
                logger.error 'Response from the VIM about the error: ' + response.to_s

                # Request VIM to delete the stack
                # response, errors = delete_stack_with_wait(stack_url, auth_token)
                # logger.debug 'Response from VIM to destroy allocated resources: ' + response.to_json
                logger.error 'VIM ERROR: ' + response['stack']['stack_status_reason'].to_s
                vnfr.push(lifecycle_event_history: stack_info['stack']['stack_status'])
                vnfr.update_attributes!(
                    vnf_status: 2
                )

                message = { status: 'ERROR_CREATING', vnfd_id: vnfr.vnfd_reference, vnfr_id: vnfr.id, stack_resources: response }
                nsmanager_callback(stack_info['ns_manager_callback'], message)

                # Delete the VNFR from the database
                # vnfr.destroy
            end
        end

        halt 200
    end

    def !(obj)
        super
    end
end
