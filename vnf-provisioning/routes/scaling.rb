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
# @see VnfProvisioning
class Scaling < VnfProvisioning
    # @method post_vnf_instances_scale_out
    # @overload post '/vnf-instances/scaling/:id/scale_out'
    # Post a Scale out request
    # @param [JSON]
    post '/:vnfr_id/scale_out' do |vnfr_id|
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'VNFR record not found'
            halt 404
        end

        # Validate JSON format
        scale_info = parse_json(request.body.read)
        # logger.debug 'Scale out: ' + scale_info.to_json
        halt 400, 'VNFD not found' unless scale_info.key?('vnfd')

        vnfd = scale_info['vnfd']
        vnf_flavour = vnfd['vnfd']['deployment_flavours'].find { |dF| dF['flavour_key'] == vnfr['deployment_flavour'] }['id']

        # check if the VNFD can scale_info
        vdus_to_scale = []
        vnfd['vnfd']['vdu'].each do |vdu|
            next unless vdu['scale_in_out']['maximum'] > 1
            logger.info "VDU #{vdu['id']} can scale."
            # check if the VNFR can scale_out
            scaled_vdu = []
            vnfr['scale_resources'].each do |scaled_resource|
                if scaled_resource.key?('vdus')
                    scaled_vdu.push(scaled_resource['vdus'].find { |v| v == vdu['id'] })
                end
            end
            if scaled_vdu.size < vdu['scale_in_out']['maximum'] - 1
                vdu_info = vnfr['vms'].find { |res| res['id'] == vdu['id'] }
                vdus_to_scale << vdu_info
            end
        end

        halt 200, 'No VDUs to scale.' if vdus_to_scale.empty?
        vdus_id_to_scale = []
        vdus_to_scale.each do |vdu|
            vdus_id_to_scale.push(vdu['id'])
        end

        lifecycle_events_values = {}
        event = 'scaling_out'

        # send reqeuest to HEAT generator with the VIM info
        logger.debug 'Send VNFD to Hot Generator'
        hot_generator_message = {
            vnf: vnfd,
            vnfr_id: vnfr['id'],
            security_group_id: vnfr['security_group_id'],
            public_network_id: vnfr['public_network_id'],
            networks_id: vnfr['vlr_instances'],
            vdus_deployed_info: vdus_to_scale
        }
        # vnfd, tnova_flavour, networks_id, security_group_id, vdus_deployed_info
        begin
            hot = parse_json(RestClient.post(settings.hot_generator + '/scale/' + vnf_flavour, hot_generator_message.to_json, content_type: :json, accept: :json))
        rescue Errno::ECONNREFUSED
            halt 500, 'HOT Generator unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        logger.debug 'HEAT template generated'

        vim_info = scale_info['auth']
        vim_info['keystone'] = vim_info['url']['keystone']
        vim_info['heat'] = vim_info['url']['heat']

        # Request VIM to provision a VNF
        name = vnfd['vnfd']['name'].delete(' ') + '_' + vnfr['_id'] + '_scaling_out_' + vnfr['scale_resources'].size.to_s
        response = provision_vnf(vim_info, name, hot)
        logger.debug 'Provision response: ' + response.to_json

        stack_url = response['stack']['links'][0]['href']
        vnfr.push(scale_resources: { stack_url: stack_url, name: name, vdus: vdus_id_to_scale })
        create_thread_to_monitor_stack(vnfr['_id'], stack_url, vim_info, vnfr['notifications'][0], vnfr['scale_resources'][vnfr['scale_resources'].size - 1])

        vnfr.push(lifecycle_event_history: "Executed a #{event}")

        halt 200, 'Scale out ok'
    end

    # @method post_vnf_instances_scale_in
    # @overload post '/vnf-instances/scaling/:id/scale_in'
    # Post a Scale in request
    # @param [JSON]
    post '/:vnfr_id/scale_in' do |vnfr_id|
        halt 415 unless request.content_type == 'application/json'

        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'VNFR record not found'
            halt 404
        end

        # Validate JSON format
        scale_info = parse_json(request.body.read)
        # logger.debug 'Scale out: ' + scale_info.to_json
        halt 400, 'VNFD not found' unless scale_info.key?('vnfd')

        event = 'scaling_in'

        halt 200, 'Nothing to scale in.' if vnfr['scale_resources'].empty?

        resource = vnfr['scale_resources'][vnfr['scale_resources'].size - 1]
        logger.debug resource
        logger.debug 'Using scaling-in saved events...'
        
        scaling_in_events = {}
        logger.debug vnfr['lifecycle_events_values'][event]
        vnfr['lifecycle_events_values'][event].each do |param, value|
            scaling_in_events[param] = value
        end

        # Build mAPI request
        mapi_request = {
            event: event,
            vnf_controller: vnfr['vnf_addresses']['controller'],
            parameters: scaling_in_events
        }
        logger.debug 'mAPI request: ' + mapi_request.to_json

        # Send request to the mAPI
        response = sendCommandToMAPI(vnfr_id, mapi_request)

        # wait 60 seconds?
        logger.info 'Waiting 60 seconds...'
        # sleep(60)

        vim_info = scale_info['auth']
        vim_info['keystone'] = vim_info['url']['keystone']
        vim_info['heat'] = vim_info['url']['heat']

        resource = vnfr['scale_resources'][vnfr['scale_resources'].size - 1]
        stack_url = resource['stack_url']
        logger.info 'Sending request to Openstack for Scale IN'
        response, errors = delete_stack_with_wait(stack_url, vim_info['token'])
        vnfr.pull(scale_resources: resource)
        logger.info 'Scale in correct'

        # Update the VNFR event history
        vnfr.push(lifecycle_event_history: "Executed a #{mapi_request[:event]}")
        halt 200, 'Scale in done.'
    end

    # @method post_vnf_instances_scale_out
    # @overload post '/vnf-instances/scaling/:id/scale_out'
    # Post a Scale out request
    # @param [JSON]
    # DEPRECATED
    post '/:vnfr_id/auto_scale_out' do
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        scale_info = parse_json(request.body.read)
        # logger.debug 'Scale out: ' + scale_info.to_json
        halt 400, 'NS Manager callback URL not found' unless scale_info.key?('vnfd')

        vnfr = scale_info['vnfr']
        lifecycle_events_values = {}
        event = 'scaling_out'

        vnfr['scale_resources'].each do |resource|
            logger.debug resource
            logger.info 'Sending request to Openstack for Scale OUT'
            begin
                logger.error resource['scale_out']
                response = RestClient.post resource['scale_out'], '', accept: :json
            rescue Errno::ECONNREFUSED
                halt 500, 'VIM unreachable'
            rescue => e
                logger.error 'ERROR sending scale_out to the VIM.'
                logger.error e
                logger.error e.response
                halt e.response.code, e.response.body
            end
            logger.error response
            logger.debug 'Scale out from Openstack is ok.'

            logger.info 'Authentication to VIM for get IDs or IPs of the scaled_resource'
            vim_info = scale_info['auth']
            vim_info['keystone'] = vim_info['url']['keystone']
            vim_info['heat'] = vim_info['url']['heat']
            # token_info = request_auth_token(vim_info)
            # tenant_id = token_info['access']['token']['tenant']['id']
            # auth_token = token_info['access']['token']['id']
            auth_token = vim_info['token']
            tenant_id =  vim_info['tenant_id']

            logger.info 'Getting AutoScaling resource'
            #       begin
            #         response, errors = parse_json(RestClient.get "#{vim_info['heat']}/#{tenant_id}/stacks/#{resource['id']}", 'X-Auth-Token' => auth_token, :accept => :json)
            #       rescue Errno::ECONNREFUSED
            #         halt 500, 'VIM unreachable'
            #       rescue => e
            #         logger.error e.response
            #         halt e.response.code, e.response.body
            #       end
            #
            #       logger.info "GET AutoscalingGroup stack:"
            #       logger.info response
            #       stack_id = response['stack']['id']
            #
            #       #get instances of the scaling group
            #       begin
            #         response, errors = parse_json(RestClient.get "#{vim_info['heat']}/#{tenant_id}/stacks/#{resource['id']}/#{stack_id}/resources", 'X-Auth-Token' => auth_token, :accept => :json)
            #       rescue Errno::ECONNREFUSED
            #         halt 500, 'VIM unreachable'
            #       rescue => e
            #         logger.error e.response
            #         halt e.response.code, e.response.body
            #       end
            #
            #       logger.info "GET Resources of AutoscalingGroup stack:"
            #       logger.info response
            #
            #       response['resources'].each do |res|
            #         logger.info res['physical_resource_id']
            #         logger.info res['resource_name']
            #       end

            # get base stack in order to read the OutPuts, the outputs are updated in real time? sleep is required?
            begin
                response, errors = parse_json(RestClient.get(vnfr['stack_url'], 'X-Auth-Token' => vim_info['token'], :accept => :json))
            rescue Errno::ECONNREFUSED
                halt 500, 'VIM unreachable'
            rescue => e
                logger.error e.response
                halt e.response.code, e.response.body
            end

            logger.info 'General STACK resource:'
            logger.info response['stack']['outputs']
            outputs = response['stack']['outputs']
            outputs.each do |output|
                logger.debug vnfr['lifecycle_info']
                logger.debug vnfr['lifecycle_info']['events']
                logger.debug vnfr['lifecycle_info']['events'][event]
                JSON.parse(vnfr['lifecycle_info']['events'][event]['template_file']).each do |_id, parameter|
                    logger.debug parameter
                    parameter_match = parameter.delete(' ').match(/^get_attr\[(.*)\]$/i).to_a
                    string = parameter_match[1].split(',').map(&:strip)
                    key_string = string.join('#')
                    logger.debug 'Key string: ' + key_string.to_s + '. Out_key: ' + output['output_key'].to_s
                    if output['output_key'] =~ /^.*#vdus/i
                        lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                        if output['output_value'].is_a? Enumerable
                            logger.error output['output_value']
                            lifecycle_events_values[event][output['output_key']] = output['output_value'][output['output_value'].size - 1]
                        else
                            lifecycle_events_values[event][output['output_key']] = output['output_value']
                        end
                    elsif string[2] == 'PublicIp' && output['output_key'] =~ /^.*#PublicIp/i
                        logger.error 'Public....'
                        logger.error key_string
                        lifecycle_events_values[event] = {} unless lifecycle_events_values.key?(event)
                        if output['output_value'].is_a? Enumerable
                            logger.error output['output_value']
                            lifecycle_events_values[event][output['output_key']] = output['output_value'][output['output_value'].size - 1]
                        else
                            lifecycle_events_values[event][output['output_key']] = output['output_value']
                        end
                    end
                end
            end
        end

        logger.info 'Lifecycle events...'
        logger.info lifecycle_events_values
        logger.info vnfr['lifecycle_info']
        logger.info vnfr['vnf_addresses']['controller']
        vnfr['lifecycle_events_values'][event] = lifecycle_events_values[event]
        logger.info vnfr['lifecycle_events_values'][event]

        # Build mAPI request
        mapi_request = {
            event: event,
            vnf_controller: vnfr['vnf_addresses']['controller'],
            parameters: vnfr['lifecycle_events_values'][event]
        }
        logger.debug 'mAPI request: ' + mapi_request.to_json

        # Send request to the mAPI
        begin
            response = RestClient.put settings.mapi + '/vnf_api/' + params[:vnfr_id] + '/config/', mapi_request.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            halt 500, 'mAPI unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        # Update the VNFR event history
        vnfr['lifecycle_event_history'].push("Executed a #{mapi_request[:event]}")
        # vnfr.update_attributes

        halt 200, 'Scale out ok'
    end

    # @method post_vnf_instances_scale_in
    # @overload post '/vnf-instances/scaling/:id/scale_in'
    # Post a Scale in request
    # @param [JSON]
    # DE
    post '/:vnfr_id/auto_scale_in' do
        # TODO

        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        scale_info = parse_json(request.body.read)
        # logger.debug 'Scale out: ' + scale_info.to_json
        halt 400, 'NS Manager callback URL not found' unless scale_info.key?('vnfd')

        vnfr = scale_info['vnfr']
        event = 'scaling_in'

        vnfr['scale_resources'].each do |resource|
            logger.debug resource
            logger.info 'Sending request to Openstack for Scale IN'
            begin
                logger.error resource['scale_out']
                response = RestClient.post resource['scale_in'], '', accept: :json
            rescue Errno::ECONNREFUSED
                halt 500, 'VIM unreachable'
            rescue => e
                logger.error 'ERROR sending scale_in to the VIM.'
                logger.error e
                logger.error e.response
                halt e.response.code, e.response.body
            end
        end

        # Build mAPI request
        mapi_request = {
            event: event,
            vnf_controller: vnfr['vnf_addresses']['controller'],
            parameters: vnfr['lifecycle_events_values'][event]
        }
        logger.debug 'mAPI request: ' + mapi_request.to_json

        # Send request to the mAPI
        begin
            response = RestClient.put settings.mapi + '/vnf_api/' + params[:vnfr_id] + '/config/', mapi_request.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            halt 500, 'mAPI unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        # Update the VNFR event history
        vnfr['lifecycle_event_history'].push("Executed a #{mapi_request[:event]}")
        halt 200, 'Scale in done.'
    end
end
