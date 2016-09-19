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
  get '/network-service/:nsr_id' do
    begin
      vnfrs = Vnfr.where(nsr_instance: params[:nsr_id])
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
    halt 400, 'NS Manager callback URL not found' unless instantiation_info.has_key?('callback_url')

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
          nsr_instance: Array(instantiation_info['ns_id']),
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
          scale_info: nil,
          scale_resources: [],
          outputs: [],
          lifecycle_info: vnf['vnfd']['vnf_lifecycle_events'].find { |lifecycle| lifecycle['flavor_id_ref'].downcase == vnf_flavour.downcase },
          lifecycle_events_values: nil)
    rescue Moped::Errors::OperationFailure => e
      return 400, 'ERROR: Duplicated VNF ID' if e.message.include? 'E11000'
      return 400, e.message
    end

    # Convert VNF to HOT (call HOT Generator)
    halt 400, 'No T-NOVA flavour defined.' unless instantiation_info.has_key?('flavour')
    logger.debug "Send VNFD to Hot Generator"
    hot_generator_message = {
        vnf: vnf,
        vnfr_id: vnfr.id,
        security_group_id: instantiation_info['security_group_id'],
        networks_id: instantiation_info['reserved_resources']['networks'],
        routers_id: instantiation_info['reserved_resources']['routers'],
        public_network_id: instantiation_info['reserved_resources']['public_network_id'],
        dns_server: instantiation_info['reserved_resources']['dns_server']
    }
    begin
      hot = parse_json(RestClient.post settings.hot_generator + '/hot/' + vnf_flavour, hot_generator_message.to_json, :content_type => :json, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'HOT Generator unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.debug "HEAT template generated"
    vim_info = {
        'keystone' => instantiation_info['auth']['url']['keystone'],
        'tenant' => instantiation_info['auth']['tenant'],
        'username' => instantiation_info['auth']['username'],
        'password' => instantiation_info['auth']['password'],
        'heat' => instantiation_info['auth']['url']['orch']
    }

    # Request VIM to provision a VNF
    response = provision_vnf(vim_info, vnf['vnfd']['name'].delete(' ') + "_" + vnfr.id, hot)
    logger.debug 'Provision response: ' + response.to_json

    vdu = []
    vdu0 = {}
    vdu0['vnfc_instance'] = response['stack']['links'][0]['href']
    vdu0['id'] = response['stack']['id']
    vdu0['type'] = 0
    vdu << vdu0

    # Update the VNFR
    vnfr.push(lifecycle_event_history: 'CREATE_IN_PROGRESS')
    vnfr.update_attributes!(
        stack_url: response['stack']['links'][0]['href'],
        vdu: vdu
    )
    vlrs = []
    vnf['vnfd']['vlinks'].each do |vlink|
      vlrs << {:id => vlink['id'], :alias=> vlink['alias']}
    end
    vnfr.update_attributes!(vlr_instances: vlrs)
    ports = []
    vnf['vnfd']['vdu'].each do |vdu|
      vdu['connection_points'].each do |port|
        ports << {:id => port['id'], :vlink_ref=> port['vlink_ref']}
      end
    end
    vnfr.update_attributes!(port_instances: ports)

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
  get '/vnf-instances/:vnfr_id' do
    begin
      vnfr = Vnfr.find(params[:vnfr_id])
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
  post '/vnf-instances/:vnfr_id/destroy' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    destroy_info = parse_json(request.body.read)
    logger.debug 'Destroy info: ' + destroy_info.to_json

    # Request an auth token from the VIM
    vim_info = {
        'keystone' => destroy_info['auth']['url']['keystone'],
        'tenant' => destroy_info['auth']['tenant'],
        'username' => destroy_info['auth']['username'],
        'password' => destroy_info['auth']['password']
    }
    token_info = request_auth_token(vim_info)
    auth_token = token_info['access']['token']['id']

    # Find VNFR
    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end

    #if the stack contains nested templates, remove nesed before
    resources = getStackResources(vnfr.stack_url, auth_token)
    resources.each do |resource|
      if resource['resource_type'] == 'OS::Heat::AutoScalingGroup'
        stack_url = resource['links'].find { |link| link['rel'] == "nested" }['href']
        response = delete_stack_with_wait(stack_url, auth_token)
        logger.debug 'VIM response to destroy the AutoScalingGroup: ' + response.to_json
      end
    end

    # Requests the VIM to delete the stack
    response = delete_stack_with_wait(vnfr.stack_url, auth_token)

    logger.debug 'VIM response to destroy: ' + response.to_json

    # Delete the VNFR from mAPI
    begin
      response = RestClient.delete "#{settings.mapi}/vnf_api/#{vnfr.id}/", 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'mAPI unreachable'
    rescue RestClient::ResourceNotFound
      puts "Already removed from the mAPI."
    rescue => e
      puts e
      logger.error e
      #logger.error e.response
      #halt e.response.code, e.response.body
    end

    # Delete the VNFR from the database
    vnfr.destroy
    halt 200, response.body
  end

  # @method post_vnf_provisioning_instances_id_config
  # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/config'
  #   Request to execute a lifecycle event
  #   @param [String] vnfr_id the VNFR ID
  #   @param [JSON]
  # Request to execute a lifecycle event
  put '/vnf-instances/:vnfr_id/config' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    config_info = parse_json(request.body.read)

    # Return if have an invalid event type
    halt 400, 'Invalid event type.' unless ['start', 'stop', 'restart', 'scale-in', 'scale-out'].include? config_info['event'].downcase

    # Get VNFR stack info
    vnfr = Vnfr.find(params[:vnfr_id])

    # Return if event doesn't have information
    halt 400, 'Event has no information' if vnfr.lifecycle_info['events'][config_info['event']].nil?

    # Build mAPI request
    mapi_request = {
        event: config_info['event'],
        vnf_controller: vnfr.vnf_addresses['controller'],
        parameters: vnfr.lifecycle_events_values[config_info['event']]
    }
    logger.debug 'mAPI request: ' + mapi_request.to_json

    # Send request to the mAPI
    begin
      if mapi_request[:event].downcase == 'start'
        response = RestClient.post settings.mapi + '/vnf_api/' + params[:vnfr_id] + '/config/', mapi_request.to_json, :content_type => :json, :accept => :json
      else
        response = RestClient.put settings.mapi + '/vnf_api/' + params[:vnfr_id] + '/config/', mapi_request.to_json, :content_type => :json, :accept => :json
      end
    rescue Errno::ECONNREFUSED
      halt 500, 'mAPI unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    # Update the VNFR event history
    vnfr.push(lifecycle_event_history: "Executed a #{mapi_request[:event]}")

    halt response.code, response.body
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

    # Request an auth token
    token_info = request_auth_token(stack_info['vim_info'])
    auth_token = token_info['access']['token']['id']

    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error 'VNFR record not found'
      halt 404
    end

    # If stack is in create complete state
    if params[:status] == 'create_complete'
      logger.debug 'Create complete'

      begin
        response = parse_json(RestClient.get vnfr.stack_url + "/resources", 'X-Auth-Token' => auth_token, :content_type => :json)
      rescue Errno::ECONNREFUSED
        halt 500, 'VIM unreachable'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end

      logger.debug "Output received from Openstack:"
      logger.debug stack_info['stack']['outputs']

      #map ports to openstack_port_id
      resources = response['resources']
      vnfr.port_instances.each do |port|
        puts port['id']
        if !resources.find { |res| res['resource_name'] == port['id'] }.nil?
          port['physical_resource_id'] = resources.find { |res| res['resource_name'] == port['id'] }['physical_resource_id']
        end
      end

      outputs = []
      stack_info['stack']['outputs'].select do |output|
        outputs << {:key => output['output_key'], :value => output['output_value']}
      end

      #update vnfr with the key generated in the stack
      private_key = outputs.find { |res| res[:key] == "private_key" }
      vnfr.lifecycle_info["authentication"] = private_key[:value]

      # Send the VNFR to the mAPI
      if !settings.mapi.nil?
        registerRequestmAPI(vnfr)
      end

      sleep(2)
      vms_id = {}
      lifecycle_events_values = {}
      vnf_addresses = {}
      scale_urls = {}
      scale_resources = []
      stack_info['stack']['outputs'].select do |output|
        logger.info output['output_key']
        # If the output is an ID

        if output['output_key'] == "private_key"
          #do nothing
        elsif output['output_key'] =~ /^.*#id$/i
          vms_id[output['output_key'].match(/^(.*)#id$/i)[1]] = output['output_value']
        elsif output['output_key']  =~ /^.*#scale_in_url/i
          scale_resource = scale_resources.find { |res| res[:vdu] == output['output_key'].match(/^(.*)#scale_in_url/i)[1] }
          if scale_resource.nil?
            scale_resources << {:vdu => output['output_key'].match(/^(.*)#scale_in_url/i)[1], :scale_in => output['output_value']}
          else
            scale_resource[:scale_in] = output['output_value']
          end
        elsif output['output_key']  =~ /^.*#scale_out_url/i
          scale_resource = scale_resources.find { |res| res[:vdu] == output['output_key'].match(/^(.*)#scale_out_url/i)[1] }
          if scale_resource.nil?
            scale_resources << {:vdu => output['output_key'].match(/^(.*)#scale_out_url/i)[1], :scale_out => output['output_value']}
          else
            scale_resource[:scale_out] = output['output_value']
          end
        elsif output['output_key'] =~ /^.*#scale_group/i
          scale_resource = scale_resources.find { |res| res[:vdu] == output['output_key'].match(/^(.*)#scale_group/i)[1] }
          if scale_resource.nil?
            scale_resources << {:vdu => output['output_key'].match(/^(.*)#scale_group/i)[1], :id => output['output_value']}
          else
            scale_resource[:id] = output['output_value']
          end
        elsif output['output_key'] =~ /^.*#vdus/i
          vms_id[output['output_key']] = output['output_value']
        elsif output['output_key'] =~ /^.*#networks/i
          #TODO
          #scale_resource = scale_resources.find { |res| res[:vdu] == output['output_key'].match(/^(.*)#networks/i)[1] }
          #if scale_resource.nil?
          #  scale_resources << {:vdu => output['output_key'].match(/^(.*)#scale_out_url/i)[1], :networks => output['output_value']}
          #else
          #  scale_resource[:networks] = output['output_value']
          #end
          #vnf_addresses[output['output_key']] = output['output_value']
        else

          if output['output_key'] =~ /^.*#PublicIp$/i
#            vnf_addresses['controller'] = output['output_value']
          end

          #other parameters
          vnfr.lifecycle_info['events'].each do |event, event_info|
            unless event_info.nil?
              JSON.parse(event_info['template_file']).each do |id, parameter|

                parameter_match = parameter.delete(' ').match(/^get_attr\[(.*)\]$/i).to_a
                string = parameter_match[1].split(",").map(&:strip)
                key_string = string.join("#")
                logger.debug "Key string: " + key_string.to_s + ". Out_key: " + output['output_key'].to_s

                if string[1] == "PublicIp" #DEPRECATED: to be removed when all VNF develpers uses the new form
                  vnf_addresses[output['output_key']] = output['output_value']
                  lifecycle_events_values[event] = {} unless lifecycle_events_values.has_key?(event)
                  lifecycle_events_values[event][key_string] = output['output_value']
                elsif string[2] == "PublicIp"
                  if key_string == output['output_key']
                    if id == 'controller'
                      vnf_addresses['controller'] = output['output_value']
                    end
                    vnf_addresses[output['output_key']] = output['output_value']
                    lifecycle_events_values[event] = {} unless lifecycle_events_values.has_key?(event)
                    lifecycle_events_values[event][key_string] = output['output_value']
                  end
                elsif output['output_key'] =~ /^#{parameter_match[1]}##{parameter_match[2]}$/i
                  vnf_addresses["#{parameter_match[1]}"] = output['output_value'] if parameter_match[2] == 'ip' && !vnf_addresses.has_key?("#{parameter_match[1]}") # Only to populate VNF
                  lifecycle_events_values[event] = {} unless lifecycle_events_values.has_key?(event)
                  lifecycle_events_values[event]["#{parameter_match[1]}##{parameter_match[2]}"] = output['output_value']
                elsif output['output_key'] == id #'controller'
                  lifecycle_events_values[event] = {} unless lifecycle_events_values.has_key?(event)
                  lifecycle_events_values[event][key_string] = output['output_value']
                end
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
          lifecycle_events_values: lifecycle_events_values,
          scale_info: scale_urls,
          scale_resources: scale_resources)

      # Build message to send to the NS Manager callback
      vnfi_id = []
      vnfr.vms_id.each { |key, value| vnfi_id << value }
      message = {vnfd_id: vnfr.vnfd_reference, vnfi_id: vnfi_id, vnfr_id: vnfr.id, vnf_addresses: vnf_addresses, stack_resources: vnfr}
      nsmanager_callback(stack_info['ns_manager_callback'], message)
    else
      # If the stack has failed to create
      if params[:status] == 'create_failed'
        logger.debug 'Created failed'

        # Request VIM information about the error
        begin
          response = JSON.parse(RestClient.get vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json)
        rescue Errno::ECONNREFUSED
          halt 500, 'VIM unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        puts response
        logger.error 'Response from the VIM about the error: ' + response.to_s

        # Request VIM to delete the stack
        begin
#          response = RestClient.delete vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VIM unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        logger.debug 'Response from VIM to destroy allocated resources: ' + response.to_json
        logger.error 'VIM ERROR: ' + response['stack']['stack_status_reason'].to_s
        vnfr.push(lifecycle_event_history: stack_info['stack']['stack_status'])
        vnfr.update_attributes!(
            vnf_status: 2)

        message = {status: "ERROR_CREATING", vnfd_id: vnfr.vnfd_reference, vnfr_id: vnfr.id, stack_resources: response}
        nsmanager_callback(stack_info['ns_manager_callback'], message)

        # Delete the VNFR from the database
        #vnfr.destroy
      end
    end

    halt 200

  end

  def !(obj)
    super
  end

end
