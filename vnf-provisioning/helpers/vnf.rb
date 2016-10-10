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
# @see ProvisioningHelper
module ProvisioningHelper
    # Checks if a JSON message is valid
    #
    # @param [JSON] message some JSON message
    # @return [Hash] the parsed message
    def parse_json(message)
        # Check JSON message format
        begin
            parsed_message = JSON.parse(message) # parse json message
        rescue JSON::ParserError => e
            # If JSON not valid, return with errors
            logger.error "JSON parsing: #{e}"
            halt 400, e.to_s + "\n"
        end

        parsed_message
    end

    # Method which lists all available interfaces
    #
    # @return [Array] an array of hashes containing all interfaces
    def interfaces_list
        [
            {
                uri: '/',
                method: 'GET',
                purpose: 'REST API Structure and Capability Discovery'
            },
            {
                uri: '/vnf-provisioning/vnf-instances',
                method: 'POST',
                purpose: 'Provision a VNF'
            },
            {
                uri: '/vnf-provisioning/vnf-instances/:id/destroy',
                method: 'POST',
                purpose: 'Destroy a VNF'
            }
        ]
    end

    # Request an auth token from the VIM
    #
    # @param [Hash] auth_info the keystone url, the tenant name, the username and the password
    # @return [Hash] the auth token and the tenant id
    def request_auth_token(vim_info)
        # Build request message
        request = {
            auth: {
                tenantName: vim_info['tenant'],
                passwordCredentials: {
                    username: vim_info['username'],
                    password: vim_info['password']
                }
            }
        }

        # GET auth token
        begin
            response = RestClient.post "#{vim_info['keystone']}/tokens", request.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            raise 500, 'Reserved stack can not be removed'
        #      halt 500, 'VIM unreachable'
        rescue => e
            logger.error e

            if e.response.nil?
                raise 400, 'Reserved stack can not be removed'
            #        halt 500, e
            else
                logger.error e.response
            end

            #      halt e.response.code, e.response.body
        end

        parse_json(response)
    end

    # Provision a VNF
    #
    # @param [Hash] auth_info the keystone url, the tenant name, the username and the password
    # @param [String] heat_url the Heat API URL
    # @param [String] vnf_name The name of the VNF
    # @param [Hash] hot the generated Heat template
    def provision_vnf(vim_info, vnf_name, hot)
        # Request an auth token
        token_info = request_auth_token(vim_info)
        tenant_id = token_info['access']['token']['tenant']['id']
        auth_token = token_info['access']['token']['id']

        # Requests VIM to provision the VNF
        begin
            response = parse_json(RestClient.post("#{vim_info['heat']}/#{tenant_id}/stacks", { stack_name: vnf_name, template: hot }.to_json, 'X-Auth-Token' => auth_token, :content_type => :json, :accept => :json))
        rescue Errno::ECONNREFUSED
            halt 500, 'VIM unreachable'
        rescue => e
            logger.error e.response
            logger.error e.response.code
            logger.error e.response.body
            halt e.response.code, e.response.body
        end

        response
    end

    # Monitor stack state
    #
    # @param [String] url the HEAT URL for the stack
    # @param [String] auth_token the auth token to authenticate with the VIM
    def create_thread_to_monitor_stack(vnfr_id, stack_url, vim_info, ns_manager_callback, scale_resources=nil)
        # Check when stack change state
        thread = Thread.new do
            sleep_time = 10 # set wait time in seconds

            begin
                # Request an auth token
                token_info = request_auth_token(vim_info)
                auth_token = token_info['access']['token']['id']

                begin
                    response = parse_json(RestClient.get(stack_url, 'X-Auth-Token' => auth_token, :accept => :json))
                rescue Errno::ECONNREFUSED
                    halt 500, 'VIM unreachable'
                rescue => e
                    logger.error e.response
                end

                sleep sleep_time # wait x seconds

            end while response['stack']['stack_status'].casecmp('create_in_progress').zero?

            # After stack create is complete, send information back to provisioning
            response[:ns_manager_callback] = ns_manager_callback
            response[:vim_info] = vim_info # Needed to delete the stack if it failed
            if !scale_resources.nil?
                vnf_complete_parsing(vnfr_id, response, scale_resources)
            else
                begin
                    RestClient.post "http://localhost:#{settings.port}/vnf-provisioning/#{vnfr_id}/stack/#{response['stack']['stack_status'].downcase}", response.to_json, content_type: :json
                rescue Errno::ECONNREFUSED
                    halt 500, 'VNF Provisioning unreachable'
                rescue => e
                    logger.error e.response
                end
            end
        end
    end

    def vnf_complete_parsing(vnfr_id, stack_info, scale_resources)
        logger.debug 'Stack info: ' + stack_info.to_json

        begin
            vnfr = Vnfr.find(vnfr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'VNFR record not found'
            halt 404
        end

        # Request an auth token
        token_info = request_auth_token(stack_info[:vim_info])
        auth_token = token_info['access']['token']['id']

        lifecycle_events_values = {}
        vnf_addresses = {}
        scale_urls = {}
        vms_id = {}
        stack_info['stack']['outputs'].select do |output|
            if output['output_key'] == 'private_key'
                private_key = output['output_value']
            elsif output['output_key'] =~ /^.*#id$/i
                vms_id[output['output_key'].match(/^(.*)#id$/i)[1]] = output['output_value']
            else
              # other parameters
              vnfr.lifecycle_info['events'].each do |event, event_info|
                  next if event_info.nil?
                  JSON.parse(event_info['template_file']).each do |id, parameter|
                      parameter_match = parameter.delete(' ').match(/^get_attr\[(.*)\]$/i).to_a
                      string = parameter_match[1].split(',').map(&:strip)
                      key_string = string.join('#')
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
        event = "scaling_out"

        # Update the VNFR
        vnfr.push(lifecycle_event_history: stack_info['stack']['stack_status'])

        resource = vnfr['scale_resources'].find { |res| res['name'] == scale_resources[:name]}
        resource = vnfr['scale_resources'][vnfr['scale_resources'].size - 1]
        scaled_resource = vnfr['scale_resources'].find { |res| res['name'] == scale_resources[:name]}
        vnfr.pull(scale_resources: resource)

        scaled_resource['vnf_addresses'] = vnf_addresses
        scaled_resource['vms_id'] = vms_id
        scaled_resource['lifecycle_events_values'] = lifecycle_events_values
        vnfr.push(scale_resources: scaled_resource)

        if vnfr.lifecycle_info['authentication_type'] == 'PubKeyAuthentication'
            if vnfr.lifecycle_info['authentication'] == ''
                logger.info 'Public Authentication is empty. Included the key generated by Openstack.'
                #        vnfr.lifecycle_info["authentication"] = private_key
                #        vnfr.update_attributes!(lifecycle_info["authentication"] = private_key)
            end
        end

        logger.info 'Registring values to mAPI if required...'
        # Send the VNFR to the mAPI
        vnfr['lifecycle_events_values'][event] = lifecycle_events_values[event]
        logger.info vnfr['lifecycle_events_values'][event]
        logger.info lifecycle_events_values

        # Build mAPI request
        mapi_request = {
            event: event,
            vnf_controller: vnfr['vnf_addresses']['controller'],
            parameters: lifecycle_events_values['scaling_out']
        }
        logger.debug 'mAPI request: ' + mapi_request.to_json

        response = sendCommandToMAPI(vnfr['id'], mapi_request)

        # Update the VNFR event history
        vnfr['lifecycle_event_history'].push("Executed a #{mapi_request[:event]}")

        # Build message to send to the NS Manager callback
        vnfi_id = []
        vnfr.vms_id.each { |_key, value| vnfi_id << value }
        message = { vnfd_id: vnfr.vnfd_reference, vnfi_id: vnfi_id, vnfr_id: vnfr.id, vnf_addresses: vnf_addresses, stack_resources: vnfr }
        #nsmanager_callback(stack_info['ns_manager_callback'], message)

    end

    # Verify if the VDU images are accessible to download
    #
    # @param [Array] List of all VDUs of the VNF
    def verify_vdu_images(vdus)
        vdus.each do |vdu|
            logger.debug 'Verifying image: ' + vdu['vm_image'].to_s + ' from ' + vdu['id'].to_s
            next unless vdu['vm_image_format'] != 'openstack_id'
            begin
                unless RestClient.head(vdu['vm_image']).code == 200
                    logger.error "Image #{vdu['vm_image']} from #{vdu['id']} not found."
                    halt 400, "Image #{vdu['vm_image']} from #{vdu['id']} not found."
                end
            rescue => e
                logger.error "Image #{vdu['vm_image']} from #{vdu['id']} not accessible."
                halt 400, "Image #{vdu['vm_image']} from #{vdu['id']} not accessible."
            end
        end
    end

    def nsmanager_callback(ns_manager_callback, message)
        logger.debug 'NS Manager message: ' + message.to_json
        begin
            response = RestClient.post ns_manager_callback.to_s, message.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
            logger.error 'NS Manager callback down'
            halt 500, 'NS Manager callback down'
        rescue => e
            puts e
            logger.error e.response
            halt e.response.code, e.response.body
        end
    end
=begin
    def deleteStack(stack_url, auth_token)
        response = RestClient.delete stack_url, 'X-Auth-Token' => auth_token, :accept => :json
    rescue Errno::ECONNREFUSED
    # halt 500, 'VIM unreachable'
    rescue RestClient::ResourceNotFound
        logger.error 'Already removed from the VIM.'
        return 404
    rescue => e
        logger.error e.response
        return
        # halt e.response.code, e.response.body
    end

    def getStackResources(stack_url, auth_token)
        begin
            response = RestClient.get stack_url + '/resources', 'X-Auth-Token' => auth_token
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            return
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            return
        end
        resources, errors = parse_json(response)
        return 400, errors if errors

        resources['resources']
    end
=end
    def recoverMonitoredInstances
        # get list of VNF instances and filter for INIT instances

        # request to NS Manager for credentials

        # create thread
        # create_thread_to_monitor_stack(vnfr_id, stack_url, vim_info, ns_manager_callback)
    end
=begin
    def delete_stack_with_wait(stack_url, auth_token)
        status = 'DELETING'
        count = 0
        code = deleteStack(stack_url, auth_token)
        if code == 404
            status = 'DELETE_COMPLETE'
            return 200
        end
        while status != 'DELETE_COMPLETE' && status != 'DELETE_FAILED'
            sleep(5)
            begin
                response = RestClient.get stack_url, 'X-Auth-Token' => auth_token, :content_type => :json, :accept => :json
                stack_info, error = parse_json(response)
                status = stack_info['stack']['stack_status']
            rescue Errno::ECONNREFUSED
                error = { 'info' => 'VIM unrechable.' }
                return
            rescue RestClient::ResourceNotFound
                logger.info 'Stack already removed.'
                status = 'DELETE_COMPLETE'
            rescue => e
                puts 'If no exists means that is deleted correctly'
                status = 'DELETE_COMPLETE'
                logger.error e
                logger.error e.response
            end

            logger.debug 'Try: ' + count.to_s + ', status: ' + status.to_s
            if status == 'DELETE_FAILED'
                deleteStack(stack_url, auth_token)
                status = 'DELETING'
            end
            break if status == 'DELETE_COMPLETE'
            count += 1

            if count > 20
                logger.error 'Stack can not be removed'
                return 400, 'Stack can not be removed'
            end
        end
        response
    end
=end
end
