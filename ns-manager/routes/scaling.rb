#
# TeNOR - NS Manager
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
# @see ScalingController
class ScalingController< TnovaManager

  # @method post_ns_instances_scaling
  # @overload post "/ns-instances/scaling/:id/scale_out"
  # Manual scaling out given ns instance id
  # @param [string] NS instance id
  post '/:nsr_id/scale_out' do

    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      @service_catalogue = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Catalogue not registred."
    end

    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      instantiation_info, errors = parse_json(RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['nsr_id'].to_s, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.error instantiation_info['nsd_id']
    # Get NS by id
    begin
      nsd = RestClient.get @service_catalogue.host + ":" + @service_catalogue.port.to_s + '/network-services/' + instantiation_info['nsd_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.error "Scaling correct."
    logger.error response.code

    return response.code, response.body
  end

  # @method post_ns_instances_scaling
  # @overload post "/ns-instances/scaling/:id/scale_in"
  # Manual scaling in given ns instance id
  # @param [string] NS instance id
  post '/:nsr_id/scale_in' do

    begin
      @service = ServiceModel.find_by(name: "ns_provisioner")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Provisioning not registred."
    end

    begin
      @service_catalogue = ServiceModel.find_by(name: "ns_catalogue")
    rescue Mongoid::Errors::DocumentNotFound => e
      halt 500, {'Content-Type' => "text/plain"}, "NS Catalogue not registred."
    end

    return 415 unless request.content_type == 'application/json'

    # Validate JSON format
    instantiation_info = JSON.parse(request.body.read)

    # Get NS Instance by NSR id
    begin
      instantiation_info, errors = parse_json(RestClient.get @service.host + ":" + @service.port.to_s + '/ns-instances/' + params['nsr_id'].to_s, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VNF Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    logger.error instantiation_info['nsd_id']
    # Get NS by id
    begin
      nsd = RestClient.get @service_catalogue.host + ":" + @service_catalogue.port.to_s + '/network-services/' + instantiation_info['nsd_id'].to_s, 'X-Auth-Token' => @client_token
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Catalogue unreachable'
    rescue => e
      logger.error e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    begin
      response = RestClient.post @service.host + ":" + @service.port.to_s + request.fullpath, "", 'X-Auth-Token' => @client_token, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'NS Provisioning unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end
    logger.error "Scaling correct."
    logger.error response.code

    return response.code, response.body
  end


end