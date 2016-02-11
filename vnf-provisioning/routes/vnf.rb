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
# @see OrchestratorVnfProvisioning
class OrchestratorVnfProvisioning < Sinatra::Application

  before do
    if request.path_info == '/gk_credentials'
      return
    end

    if settings.environment == 'development'
      return
    end

    authorized?
  end

  # @method get_root
  # @overload get '/'
  #   Get all available interfaces
  # Get all interfaces
  get '/' do
    logger.debug 'Interfaces list: ' + interfaces_list.to_json
    halt 200, interfaces_list.to_json
  end

  # @method get_vnf-provisioning_network-service_ns_id
  # @overload get '/vnf-provisioning/network-service/:ns_id'
  #   Get all the VNFRs of a specific NS
  # Get all the VNFRs of a specific NS
  get '/vnf-provisioning/network-service/:nsr_id' do
    begin
      vnfrs = Vnfr.where(nsr_instance: params[:nsr_id])
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug 'List of VNFRs: ' + vnfrs.to_json

    halt 200, vnfrs.to_json
  end

  # @method get_vnf-provisioning_vnf-instances
  # @overload get '/vnf-provisioning/vnf-instances'
  #   Return all VNF Instances
  # Return all VNF Instances
  get '/vnf-provisioning/vnf-instances' do
    begin
      vnfrs = Vnfr.all
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug 'List of all VNFRs: ' + vnfrs.to_json

    halt 200, vnfrs.to_json
  end

  # @method post_vnf-provisioning_vnf-instances
  # @overload post '/vnf-provisioning/vnf-instances'
  #   Instantiate a VNF
  #   @param [JSON] the VNF to instantiate and auth info
  # Instantiate a VNF
  post '/vnf-provisioning/vnf-instances' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = parse_json(request.body.read)
    logger.debug 'Instantiation info: ' + instantiation_info.to_json
    halt 400, 'NS Manager callback URL not found' unless instantiation_info.has_key?('callback_url')

    vnf = instantiation_info['vnf']

    # Convert VNF to HOT (call HOT Generator)
    halt 400, 'No T-NOVA flavour defined.' unless instantiation_info.has_key?('flavour')
    hot_generator_message = {
      vnf: vnf,
      networks_id: instantiation_info['networks'],
      security_group_id: instantiation_info['security_group_id']
    }
    begin
      hot = parse_json(RestClient.post settings.hot_generator + '/hot/' + instantiation_info['flavour'], hot_generator_message.to_json, :content_type => :json, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'HOT Generator unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug 'HOT: ' + hot.to_json

    vim_info = {
      'keystone' => instantiation_info['auth']['url']['keystone'],
      'tenant' => instantiation_info['auth']['tenant'],
      'username' => instantiation_info['auth']['username'],
      'password' => instantiation_info['auth']['password'],
      'heat' => instantiation_info['auth']['url']['orch']
    }
    logger.debug 'VIM info: ' + vim_info.to_json

    # Request VIM to provision a VNF
    response = provision_vnf(vim_info, vnf['name'], hot)
    logger.debug 'Provision response: ' + response.to_json

    # Build the VNFR and store it
    begin
      vnfr = Vnfr.create!(
        nsr_instance: Array(instantiation_info['ns_id']),
        vnfd_reference: vnf['_id'],
        vim_id: instantiation_info['vim_id'],
        vlr_instances: nil,
        vnf_addresses: nil,
        vnf_status: 3,
        notifications: nil,
        lifecycle_event_history: Array('CREATE_IN_PROGRESS'),
        audit_log: nil,
        stack_url: response['stack']['links'][0]['href'],
        vms_id: nil,
        lifecycle_events: vnf['vnfd']['vnf_lifecycle_events'].find{|lifecycle| lifecycle['flavor_id_ref'].downcase == instantiation_info['flavour'].downcase}['events'],
        lifecycle_events_values: nil)
    rescue Moped::Errors::OperationFailure => e
      return 400, 'ERROR: Duplicated VNF ID' if e.message.include? 'E11000'
      return 400, e.message
    end
    logger.debug 'Created VNFR: ' + vnfr.to_json

    create_thread_to_monitor_stack(vnfr.id, vnfr.stack_url, vim_info, instantiation_info['callback_url'])
    logger.debug 'Created thread to monitor stack'

    # Send the VNFR to the mAPI
    lifecycle_event = vnf['vnfd']['vnf_lifecycle_events'].find { |event| event['flavor_id_ref'] == instantiation_info['flavour']}
    mapi_request = {id: vnfr.id.to_s, vnfd: {vnf_lifecycle_events: lifecycle_event}}
    logger.debug 'mAPI request: ' + mapi_request.to_json
    begin
      response = RestClient.post "#{settings.mapi}/vnf_api/", mapi_request.to_json, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'mAPI unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt 201, vnfr.to_json
  end

  # @method get_vnf-provisioning_vnf-instances_vnfr_id
  # @overload get '/vnf-provisioning/vnf-instances/:vnfr_id
  #   Get a specific VNFR by its ID
  # Get a specific VNFR by its ID
  get '/vnf-provisioning/vnf-instances/:vnfr_id' do
    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end
    logger.debug 'VNFR: ' + vnfr.to_json

    halt 200, vnfr.to_json
  end

  # @method post_vnf-provisioning_vnf-instances_vnfr_id_destroy
  # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/destroy'
  #   Destroy a VNF
  #   @param [String] vnfr_id the VNFR ID
  #   @param [JSON] the VNF to instantiate and auth info
  # Destroy a VNF
  post '/vnf-provisioning/vnf-instances/:vnfr_id/destroy' do
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
    logger.debug 'Token info: ' + token_info.to_json

    # Find VNFR
    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 404
    end
    logger.debug 'VNFR: ' + vnfr.to_json

    # Requests the VIM to delete the stack
    begin
      response = RestClient.delete vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.debug 'VIM response to destroy: ' + response.to_json

    # Delete the VNFR from mAPI
    begin
      response = RestClient.delete "#{settings.mapi}/vnf_api/#{vnfr.id}/", 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'mAPI unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end  

    # Delete the VNFR from the database
    vnfr.destroy

    halt 200, response.body
  end

  # @method post_vnf-provisioning_vnf-instances_vnfr_id_config
  # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/config'
  #   Request to execute a lifecycle event
  #   @param [String] vnfr_id the VNFR ID
  #   @param [JSON]
  # Request to execute a lifecycle event
  put '/vnf-provisioning/vnf-instances/:vnfr_id/config' do
    # Return if content-type is invalid
    halt 415 unless request.content_type == 'application/json'

    # Validate JSON format
    config_info = parse_json(request.body.read)

    # Return if have an invalid event type
    halt 400, 'Invalid event type.' unless ['start', 'stop', 'restart', 'scale-in', 'scale-out'].include? config_info['event'].downcase

    # Get VNFR stack info
    vnfr = Vnfr.find(params[:vnfr_id])

    # Return if event doesn't have information
    halt 400, 'Event has no information' if vnfr.lifecycle_events[config_info['event']].nil?

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

    halt response.code, response.body
  end

  # @method post_vnf-provisioning_vnfr_id_stack_status
  # @overload post '/vnf-provisioning/:vnfr_id/stack/:status'
  #   Receive a VNF status after provisioning at the VIM
  #   @param [String] vnfr_id the VNFR ID
  #   @param [String] status the VNF status at the VIM
  # Receive a VNF status after provisioning at the VIM
  post '/vnf-provisioning/:vnfr_id/stack/:status' do
    # Parse body message
    stack_info = parse_json(request.body.read)
    logger.debug 'Stack info: ' + stack_info.to_json

    begin
      vnfr = Vnfr.find(params[:vnfr_id])
    rescue Mongoid::Errors::DocumentNotFound => e
      logger.error 'VNFR record not found'
      halt 404
    end
    logger.debug 'VNFR: ' + vnfr.to_json

    # If stack is in create complete state
    if params[:status] == 'create_complete'
      logger.debug 'Create complete'

      # Read from VIM outputs and map with parameters
      vms_id = {}
      lifecycle_events_values = {}
      vnf_addresses = {}
      stack_info['stack']['outputs'].select do |output|
        # If the output is an ID
        if output['output_key'] =~ /^.*#id$/i
          vms_id[output['output_key'].match(/^(.*)#id$/i)[1]] = output['output_value']
        else
          # If the output is a Floating IP
          if output['output_key'] =~ /^.*#floating_ip$/i
            vnf_addresses['controller'] = output['output_value']
          else # Else look for the output on the lifecycle events
            vnfr.lifecycle_events.each do |event, event_info|
              unless event_info.nil?
                JSON.parse(event_info['template_file']).each do |id, parameter|
                  parameter_match = parameter.match(/^get_attr\[(.*), *(.*)\]$/i).to_a
                  if output['output_key'] =~ /^#{parameter_match[1]}##{parameter_match[2]}$/i
                    vnf_addresses["#{parameter_match[1]}"] = output['output_value'] if parameter_match[2] == 'ip' && !vnf_addresses.has_key?("#{parameter_match[1]}") # Only to populate VNF Addresses specified by ETSI 
                    lifecycle_events_values[event] = {} unless lifecycle_events_values.has_key?(event)
                    lifecycle_events_values[event]["#{parameter_match[1]}##{parameter_match[2]}"] = output['output_value']
                  end
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
        lifecycle_events_values: lifecycle_events_values)
      logger.debug 'Updated VNFR: ' + vnfr.to_json

      # Build message to send to the NS Manager callback
      vnfi_id = []
      vnfr.vms_id.each {|key, value| vnfi_id << value}
      ns_manager = { vnfd_id: vnfr.vnfd_reference, vnfi_id: vnfi_id, vnfr_id: vnfr.id}
      logger.debug 'NS Manager message: ' + ns_manager.to_json
      logger.debug 'NS Manager callback: ' + stack_info['ns_manager_callback'].to_json
      begin
        response = RestClient.post "#{stack_info['ns_manager_callback']}", ns_manager.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
        halt 500, 'NS Manager callback'
      rescue => e
        logger.error e.response
        halt e.response.code, e.response.body
      end
    else
      # If the stack has failed to create
      if params[:status] == 'create_failed'
        logger.debug 'Created failed'
        # Request an auth token
        token_info = request_auth_token(stack_info['vim_info'])
        auth_token = token_info['access']['token']['id']
        logger.debug 'Token info: ' + token_info.to_json

        # Request VIM information about the error
        begin
          response = RestClient.get vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VIM unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        logger.debug 'Response from the VIM about the error: ' + response.to_json

        # Request VIM to delete the stack
        begin
          response = RestClient.delete vnfr.stack_url, 'X-Auth-Token' => auth_token, :accept => :json
        rescue Errno::ECONNREFUSED
          halt 500, 'VIM unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end
        logger.debug 'Response from VIM to destroy allocated resources: ' + response.to_json

        # Delete the VNFR from mAPI
        begin
          response = RestClient.delete "#{settings.mapi}/vnf_api/#{vnfr.id}/", 'X-Auth-Token' => @client_token
        rescue Errno::ECONNREFUSED
          halt 500, 'mAPI unreachable'
        rescue => e
          logger.error e.response
          halt e.response.code, e.response.body
        end

        # Delete the VNFR from the database
        vnfr.destroy
      end
    end

    halt 200

  end

end