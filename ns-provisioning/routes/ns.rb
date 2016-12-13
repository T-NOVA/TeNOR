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
# @see NsProvisioning
class Provisioner < NsProvisioning
    # @method get_ns_instances
    # @overload get "/ns-instances"
    # Gets all ns-instances
    get '/' do
        instances = if params[:status]
                        Nsr.where(status: params[:status])
                    else
                        Nsr.all
                       end

        return instances.to_json
    end

    # @method get_ns_instance_id
    # @overload get "/ns-instances/:id"
    # Get a ns-instance
    get '/:id' do
        begin
            instance = Nsr.find(params['id'])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end
        return instance.to_json
    end

    # @method post_ns_instances
    # @overload post '/ns'
    # Instantiation request
    # @param [JSON]
    # Request body: {"nsd": "descriptor", "customer_id": "some_id", "nap_id": "some_id"}'
    post '/' do
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'
        # Validate JSON format
        instantiation_info, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        nsd = instantiation_info['nsd']

        if instantiation_info['flavour'].nil?
            halt 400, 'Failed creating instance. Flavour is null'
        end

        instance = {
            nsd_id: nsd['id'],
            name: nsd['name'],
            descriptor_reference: nsd['id'],
            auto_scale_policy: nsd['auto_scale_policy'],
            connection_points: nsd['connection_points'],
            monitoring_parameters: nsd['monitoring_parameters'],
            service_deployment_flavour: instantiation_info['flavour'],
            vendor: nsd['vendor'],
            version: nsd['version'],
            # vlr
            vnfrs: [],
            lifecycle_events: nsd['lifecycle_events'],
            vnf_depedency: nsd['vnf_depedency'],
            vnffgd: nsd['vnffgd'],
            # pnfr
            resource_reservation: [],
            runtime_policy_info: [],
            status: 'INIT',
            notification: instantiation_info['callback_url'],
            lifecycle_event_history: ['INIT'],
            audit_log: [],
            marketplace_callback: instantiation_info['callback_url'],
            authentication: []
        }

        @instance = Nsr.new(instance)
        @instance.save!

        # call thread to process instantiation
        Thread.new do
            instantiate(@instance, nsd, instantiation_info)
        end

        return 201, @instance.to_json
    end

    # @method put_ns_instance_id
    # @overload put '/ns-instances/:ns_instance_id'
    # NS Instance update request
    # @param [JSON]
    put '/:ns_instance_id' do
    end

    # @method get_ns_instance_status
    # @overload gett '/ns-instances/:nsr_id/status'
    # Get instance status
    # @param [JSON]
    get '/:nsr_id/status' do
        begin
            instance = Nsr.find(params[:nsr_id])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end

        return instance['status']
    end

    # @method put_ns_instance_status
    # @overload post '/ns-instances/:nsr_id/status'
    # Update instance status
    # @param [JSON]
    put '/:id/:status' do
        body, errors = parse_json(request.body.read)

        begin
            @nsInstance = Nsr.find(params['id'])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end

        if params[:status] === 'terminate'
            logger.info 'Starting thread for removing VNF and NS instances.'
            @nsInstance.update_attribute('status', 'DELETING')
            Thread.abort_on_exception = false
            Thread.new do
                # operation = proc {
                @nsInstance['vnfrs'].each do |vnf|
                    logger.info 'Terminate VNF ' + vnf['vnfr_id'].to_s
                    logger.info 'Pop_id: ' + vnf['pop_id'].to_s
                    raise 'VNF not defined' if vnf['pop_id'].nil?

                    pop_auth = @nsInstance['authentication'].find { |pop| pop['pop_id'] == vnf['pop_id'] }
                    popUrls = pop_auth['urls']
                    callback_url = settings.manager + '/ns-instances/' + @nsInstance['id']
                    next if vnf['vnfr_id'].nil?
                    # get token
                    credentials, errors = authenticate(popUrls[:keystone], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'])
                    logger.error errors if errors
                    return if errors
                    auth = { auth: { tenant_id: credentials[:tenant_id], user_id: credentials[:user_id], token: credentials[:token], url: { keystone: popUrls[:keystone] } }, callback_url: callback_url }
                    begin
                        response = RestClient.post settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/destroy', auth.to_json, content_type: :json, 'X-Auth-Token' => settings.vnf_manager_token
                    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
                    # halt 500, 'VNF Manager unreachable'
                    rescue RestClient::ResourceNotFound
                        puts 'Already removed from the VIM.'
                        logger.error 'Already removed from the VIM.'
                    rescue RestClient::ServerBrokeConnection
                        logger.error 'VNF Manager brokes the connection due timeout.'
                        return
                    rescue => e
                        puts 'Probably an error with mAPI'
                        puts e
                        logger.error e
                        logger.error e.response
                        # halt e.response.code, e.response.body
                    end
                end

                logger.info 'VNFs removed correctly.'
                error = 'Removing instance'
                recoverState(@nsInstance, body['pop_info'], error)

                if @nsInstance['marketplace_callback'].include? "/service-selection"
                    logger.info "Sending stop to Accounting"
    				marketplace = @nsInstance['marketplace_callback'].split("/service-selection")[0]
    				begin
    					RestClient.post "#{marketplace}:8000/servicestatus/#{@nsInstance['id']}/stopped/", ""
    				rescue => e
    				end
                end
            end
            errback = proc do
                logger.error 'Error with the removing process...'
            end
            callback = proc do
                logger.info 'Removing finished correctly.'
            end
        elsif params[:status] === 'start'
            @nsInstance['vnfrs'].each do |vnf|
                logger.info 'Starting VNF ' + vnf['vnfr_id'].to_s
                event = { event: 'start' }
                begin
                    response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, content_type: :json, 'X-Auth-Token' => settings.vnf_manager_token
                rescue Errno::ECONNREFUSED
                    logger.error 'VNF Manager unreachable.'
                    halt 500, 'VNF Manager unreachable'
                rescue => e
                    logger.error e.response
                    halt e.response.code, e.response.body
                end
                @nsInstance.push(lifecycle_event_history: 'Executed a start')
            end

            @nsInstance.update_attribute('status', params['status'].to_s.upcase)
        elsif params[:status] === 'stop'
            @nsInstance['vnfrs'].each do |vnf|
                logger.debug vnf
                event = { event: 'stop' }
                begin
                    response = RestClient.put settings.vnf_manager + '/vnf-provisioning/vnf-instances/' + vnf['vnfr_id'] + '/config', event.to_json, content_type: :json, 'X-Auth-Token' => settings.vnf_manager_token
                rescue Errno::ECONNREFUSED
                    logger.error 'VNF Manager unreachable.'
                    halt 500, 'VNF Manager unreachable'
                rescue => e
                    logger.error e.response
                    halt e.response.code, e.response.body
                end
            end

            @nsInstance['status'] = params['status'].to_s.upcase
            @nsInstance
        end

        halt 200
    end

    get '/ns-instances-mapping' do
    end

    post '/ns-instances-mapping' do
    end

    delete '/ns-instances-mapping/:id' do
    end

    # @method post_ns_instances_id_instantiate
    # @overload post '/ns-instances/:id/instantiate'
    # Response from VNF-Manager, send a message to marketplace
    post '/:nsr_id/instantiate' do |nsr_id|
        logger.info 'Instantiation response about ' + nsr_id
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'
        # Validate JSON format
        response, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        callback_response = response['callback_response']
        begin
            instance = Nsr.find(nsr_id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error e
            return 404
        end
        nsd = response['nsd']

        if callback_response['status'] == 'ERROR_CREATING'
            instance.update_attribute('status', 'ERROR_CREATING')
            instance.push(lifecycle_event_history: 'ERROR_CREATING')
            instance.push(audit_log: callback_response['stack_resources']['stack']['stack_status_reason'])
            generateMarketplaceResponse(instance['notification'], { status: 'error', message: callback_response['stack_resources']['stack']['stack_status_reason'] }.to_s)
            return 200
        end

        logger.info callback_response['vnfd_id'].to_s + ' INSTANTIATED'
        instance.push(lifecycle_event_history: 'VNF ' + callback_response['vnfd_id'].to_s + ' INSTANTIATED')
        vnfr = instance['vnfrs'].find { |vnf_info| vnf_info['vnfd_id'] == callback_response['vnfd_id'] }
        instance.pull(vnfrs: vnfr)
        vnfr['vnfi_id'] = callback_response['vnfi_id']
        vnfr['status'] = 'INSTANTIATED'
        vnfr['vnf_addresses'] = callback_response['vnf_addresses']
        instance.push(vnfrs: vnfr)

        # for each VNF instantiated, read the connection point in the NSD and extract the resource id
        logger.info 'Updating VNFR virtual links'
        vnfr_resources = callback_response['stack_resources']
        nsd['vld']['virtual_links'].each do |vl|
            vl['connections'].each do |conn|
                vnf_net = conn.split('#')[1]
                vnf_id = vnf_net.split(':')[0]
                net = vnf_net.split(':ext_')[1]
                next unless vnf_id == vnfr_resources['vnfd_reference']
                logger.debug 'Searching ports for network ' + net.to_s
                next if net == 'undefined'
                vlr = vnfr_resources['vlr_instances'].find { |vlr| vlr['alias'] == net }
                next unless !vnfr_resources['port_instances'].empty? && !vlr.nil?
                vnf_ports = vnfr_resources['port_instances'].find_all { |port| port['vlink_ref'] == vlr['id'] }
                ports = {
                    ns_network: conn,
                    vnf_ports: vnf_ports
                }
                resources = instance['resource_reservation'].find { |res| res['pop_id'] == vnfr['pop_id'] }
                instance.pull(resource_reservation: resources)
                resources['ports'] << ports
                instance.push(resource_reservation: resources)
            end
        end

        logger.info 'Checking if all the VNFs are instantiated.'
        instance['vnfrs'].each do |vnf|
            vnf_instance = instance['vnfrs'].find { |vnf_info| vnf_info['vnfd_id'] == vnf['vnfd_id'] }
            if vnf_instance['status'] != 'INSTANTIATED'
                logger.info 'VNF ' + vnf['vnfd_id'].to_s + ' is not ready.'
                return
            end
        end

        #reading netfloc info from authentication
        if settings.netfloc
            instance.update_attribute('instantiation_netfloc_start_time', DateTime.now.iso8601(3))
            logger.info 'Create Netfloc HOT for each PoP...'
            logger.info instance['vnffgd']['vnffgs']
            graphs = []
            graphs_pops = []
            instance['vnffgd']['vnffgs'].each do |fg|
                vnfg = {name: fg['vnffg_id'], ports: []}
                fg['network_forwarding_path'].each do |path|
                    path['connection_points'].each do |port|
                        resource = instance['resource_reservation'].find { |resource| resource['ports'].find { |p| p[:ns_network] == port } }
                        next if resource.nil?
                        vnf_port = resource['ports'].find { |p| p[:ns_network] == port }
                        vnfg[:ports] << { pop_id: resource['pop_id'].to_s, port_id: vnf_port[:vnf_ports][0]['physical_resource_id'] }
                        graphs_pops.push(resource['pop_id'].to_s) unless graphs_pops.include?(resource['pop_id'].to_s)
                    end
                end
                graphs << vnfg
            end
            logger.info "Graphs:"
            logger.info graphs
            chains = []
            graphs_pops.each do |pop_id|
                graphs.each_with_index do |vnfg|
                    ports = vnfg[:ports].find_all{|p| p[:pop_id] == pop_id }
                    chain = []
                    ports.each do |p|
                        chain << p[:port_id]
                    end
                    chains << chain
                end
                # get credentials for each PoP
                pop_auth = instance['authentication'].find { |pop| pop['pop_id'] == pop_id }
                pop_info = pop_auth['urls']
                logger.debug pop_info['netfloc_ip']
                logger.debug pop_info['netfloc_user']
                logger.debug pop_info['netfloc_pass']
                logger.error "ERROR READING NETFLOC IP" if pop_info['wicm_ip'].nil?
                next if pop_info['netfloc_ip'].nil?
                credentials, errors = authenticate(pop_info['keystone'], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'])
                logger.error errors if errors
                token = credentials[:token]

                # generate netfloc hot template for a chain
                hot_generator_message = {
                    chains: chains,
                    odl_username: pop_info['netfloc_user'],
                    odl_password: pop_info['netfloc_pass'],
                    netfloc_ip_port: pop_info['netfloc_ip']#"10.30.0.61:8181"
                }
                logger.info 'Generating netfloc HOT template...'
                hot_template, errors = generateNetflocTemplate(hot_generator_message)
                logger.error 'Error generating Netfloc template.' if errors
                return 400, errors.to_json if errors
                logger.debug hot_template
                return 400, "error.." if hot_template.empty?
                logger.info 'Send Netfloc HOT to Openstack'
                stack_name = "Netfloc_#{instance['id'].to_s}"
                template = { stack_name: stack_name, template: hot_template }
                stack, errors = sendStack(pop_info['orch'], pop_auth[:tenant_id], template, token)
                logger.error 'Error sending Netfloc template to Openstack.' if errors
                logger.error errors if errors
                return 400, errors.to_json if errors

                stack_info, errors = create_stack_wait(pop_info['orch'], pop_auth[:tenant_id], stack_name, token, 'NS Netfloc')
                return handleError(instance, errors) if errors

                resources = instance['resource_reservation'].find { |res| res['pop_id'] == pop_id }
                instance.pull(resource_reservation: resources)
                resources['netfloc_stack'] = { id: stack['stack']['id'], stack_url: stack['stack']['links'][0]['href'] }
                instance.push(resource_reservation: resources)

                logger.debug stack
            end
            instance.update_attribute('instantiation_netfloc_end_time', DateTime.now.iso8601(3))
        end

        logger.info 'Service is ready. All VNFs are instantiated'
        instance.update_attribute('instantiation_end_time', DateTime.now.iso8601(3))
        instance.update_attribute('status', 'INSTANTIATED')
        instance.push(lifecycle_event_history: 'INSTANTIATED')

        logger.info 'Sending start command'
        Thread.new do
            sleep(5)
            begin
                RestClient.put settings.manager + '/ns-instances/' + nsr_id + '/start', {}.to_json, content_type: :json
            rescue Errno::ECONNREFUSED
                logger.error 'Connection refused with the NS Manager'
            rescue => e
                logger.error e.response
                logger.error 'Error with the start command'
            end
        end

        logger.info 'Sending statistic information to NS Manager'
        Thread.new do
            generateMarketplaceResponse(instance['notification'], instance)
            begin
                RestClient.post settings.manager + '/statistics/performance_stats', instance.to_json, content_type: :json
            rescue => e
                logger.error e
            end
        end

        if instance['resource_reservation'].find { |resource| resource.has_key?('wicm_stack')}
            logger.info 'Starting traffic redirection in the WICM'
            Thread.new do
                instance['authentication'].each do |pop_auth|
                    pop_info = pop_auth['urls']
                    logger.debug pop_info['wicm_ip']
                    logger.error "ERROR READING WICM IP" if pop_info['wicm_ip'].nil?
                    next if pop_info['wicm_ip'].nil?
                    begin
                        response = RestClient.put pop_info['wicm_ip'] + '/vnf-connectivity/' + nsr_id, '', content_type: :json, accept: :json
                    rescue => e
                        logger.error e
                    end
                    logger.info response
                end
            end
        end

        logger.info 'Starting monitoring workflow...'
        Thread.new do
            sleep(5)
            monitoringData(nsd, instance)
        end

        return 200
    end
end
