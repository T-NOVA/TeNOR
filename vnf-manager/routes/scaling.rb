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
class Scaling < VNFManager

  # @method post_vnf_provisioning_scaling_out
  # @overload post '/vnf-instances/scaling/:vnfr_id/scale_out'
  # Scale out the VNFR
  # @param [Integer] vnfr_id the vnfr ID
  post '/:vnfr_id/scale_out' do

    provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
    halt 500, errors if errors

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    scaling_info = parse_json(request.body.read)

    # Get VNF Instance by VNFR id
    begin
      vnfr = parse_json(RestClient.get provisioner.host + '/vnf-provisioning/vnf-instances/' + params['vnfr_id'].to_s, 'X-Auth-Token' => provisioner.token, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    # Get VNF by id
    begin
      vnfd = parse_json(RestClient.get catalogue.host + '/vnfs/' + vnfr['vnfd_reference'].to_s, 'X-Auth-Token' => catalogue.token, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    scale_info = {:auth => scaling_info['auth'], :vnfd => vnfd}

    # Forward the request to the VNF Provisioning
    begin
      response = RestClient.post provisioner.host + request.fullpath, scale_info.to_json, 'X-Auth-Token' => provisioner.token, :accept => :json, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end

  # @method post_vnf_provisioning_scaling_in
  # @overload post '/vnf-instances/scaling/:vnfr_id/scale_in'
  # Scale in the VNFR
  # @param [Integer] vnfr_id the vnfr ID
  post '/:vnfr_id/scale_in' do

    provisioner, errors = ServiceConfigurationHelper.get_module('vnf_provisioner')
    halt 500, errors if errors

    catalogue, errors = ServiceConfigurationHelper.get_module('vnf_catalogue')
    halt 500, errors if errors

    scaling_info = parse_json(request.body.read)

    # Get VNF Instance by VNFR id
    begin
      vnfr = parse_json(RestClient.get provisioner.host + '/vnf-provisioning/vnf-instances/' + params['vnfr_id'].to_s, 'X-Auth-Token' => provisioner.token, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    # Get VNF by id
    begin
      vnfd = parse_json(RestClient.get catalogue.host + '/vnfs/' + vnfr['vnfd_reference'].to_s, 'X-Auth-Token' => catalogue.token, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    scale_info = {:auth => scaling_info['auth'], :vnfd => vnfd}

    # Forward the request to the VNF Provisioning
    begin
      response = RestClient.post provisioner.host + request.fullpath, scale_info.to_json, 'X-Auth-Token' => provisioner.token, :accept => :json, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    halt response.code, response.body
  end


end
