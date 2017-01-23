#
# TeNOR - VNF Manager
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
# @see VNFManager
class Provisioning < VNFManager
    # @method get_vnf_provisioning_network_service_ns_id
    # @overload get '/vnf-provisioning/network-service/:ns_id'
    #   Get all the VNFRs of a specific NS
    #   @param [Integer] ns_id the network service ID
    # Get all the VNFRs of a specific NS
    get '/network-service/:ns_id' do |ns_id|
        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        # Forward the request to the VNF Provisioning
        begin
            response = RestClient.get provisioner.host + '/vnf-provisioning/network-service/' + ns_id, 'X-Auth-Token' => provisioner.token, :accept => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end

    # @method get_vnf_provisioning_vnf_instances
    # @overload get '/vnf-provisioning/vnf-instances'
    #       Return all VNF Instances
    # Return all VNF Instances
    get '/vnf-instances' do
        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        # Send request to VNF Provisioning
        begin
            response = RestClient.get provisioner.host + '/vnf-provisioning/vnf-instances', 'X-Auth-Token' => provisioner.token
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end

    # @method get_vnf_provisioning_vnf_instances
    # @overload get '/vnf-provisioning/vnf-instances'
    #       Return all VNF Instances
    # Return all VNF Instances
    get '/vnf-instances/:vnfr_id' do |vnfr_id|
        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        # Send request to VNF Provisioning
        begin
            response = RestClient.get provisioner.host + '/vnf-provisioning/vnf-instances/' + vnfr_id, 'X-Auth-Token' => provisioner.token
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end

    # @method post_vnf_provisioning_vnf_instances
    # @overload post '/vnf-provisioning/vnf-instances'
    #       Request the instantiation of a VNF
    #       @param [JSON] information about VIM and the VNFD ID
    # Request the instantiation of a VNF
    post '/vnf-instances' do
        catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
        halt 500, errors if errors

        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Validate JSON format
        instantiation_info = parse_json(request.body.read)

        # Get VNF by id
        begin
            instantiation_info['vnf'] = parse_json(RestClient.get(catalogue.host + '/vnfs/' + instantiation_info['vnf_id'].to_s, 'X-Auth-Token' => catalogue.token, :accept => :json))
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Catalogue unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        # Send provisioning info to VNF Provisioning
        begin
            response = RestClient.post provisioner.host + '/vnf-provisioning/vnf-instances', instantiation_info.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end

    # @method post_vnf_provisioning_vnf_instances_vnfr_id_destroy
    # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/destroy'
    #       Request to de-allocate the resources of a VNF
    #       @param [String] vnfr_id the VNFR ID
    #       @param [JSON] information about VIM
    # Request to de-allocate the resources of a VNF
    post '/vnf-instances/:vnfr_id/destroy' do |vnfr_id|
        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        monitoring, errors = ServiceConfigurationHelper.get_module('vnf_monitoring')
        # halt 500, errors if errors
        unless errors
            begin
                response = RestClient.delete monitoring.host + "/vnf-monitoring/subcription/#{vnfr_id}", 'X-Auth-Token' => monitoring.token, :content_type => :json, :accept => :json
            rescue Errno::ECONNREFUSED
            # halt 500, 'VNF Monitoring unreachable'
            rescue => e
                logger.error e
                # logger.error e.response
                # halt e.response.code, e.response.body
            end
        end

        # Forward the request to the VNF Provisioning
        begin
            response = RestClient.post provisioner.host + "/vnf-provisioning/vnf-instances/#{vnfr_id}/destroy", request.body, 'X-Auth-Token' => provisioner.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end

    # @method post_vnf_rovisioning_vnf_instances_vnfr_id_config
    # @overload post '/vnf-provisioning/vnf-instances/:vnfr_id/config'
    #       Request to execute a lifecycle event
    #       @param [String] vnfr_id the VNFR ID
    #       @param [JSON] information about VIM
    # Request to execute a lifecycle event
    put '/vnf-instances/:vnfr_id/config' do |vnfr_id|
        provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
        halt 500, errors if errors

        # Return if content-type is invalid
        halt 415 unless request.content_type == 'application/json'

        # Read request body
        config_info = parse_json(request.body.read)

        # Forward the request to the VNF Provisioning
        begin
            response = RestClient.put provisioner.host + '/vnf-provisioning/vnf-instances/' + vnfr_id + '/config', config_info.to_json, 'X-Auth-Token' => provisioner.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Provisioning unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        halt response.code, response.body
    end
end
