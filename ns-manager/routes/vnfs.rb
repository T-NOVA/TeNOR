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
# @see VNFCatalogue
class VNFCatalogue < TnovaManager
    # @method get_vnfs
    # @overload get "/vnfs"
    # Get the VNFs list
    get '/' do
        catalogue, errors = ServiceConfigurationHelper.get_module('vnf_manager')
        halt 500, errors if errors

        begin
            response = RestClient.get catalogue.host + request.fullpath, 'X-Auth-Token' => catalogue.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Manager unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end
        return response.code, response.body
    end

    # @method get_vnfs_id
    # @overload get "/vnfs/:vnf_id"
    # Get specific VNF
    # @param [string] vnf_id The VNFD id
    get '/:vnf_id' do
        catalogue, errors = ServiceConfigurationHelper.get_module('vnf_manager')
        halt 500, errors if errors

        begin
            response = RestClient.get catalogue.host + request.fullpath, 'X-Auth-Token' => catalogue.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Manager unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        return response.code, response.body
    end

    # @method post_vnfs
    # @overload post "/vnfs"
    # Post a new VNF
    post '/' do
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'

        catalogue, errors = ServiceConfigurationHelper.get_module('vnf_manager')
        halt 500, errors if errors

        begin
            response = RestClient.post catalogue.host + request.fullpath, request.body.read, 'X-Auth-Token' => catalogue.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Manager unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        # updateStatistics('vnfs_created_requests')
        return response.code, response.body
    end

    # @method put_vnfs
    # @overload put "/vnfs/:vnf_id"
    # Update a VNF
    # @param [string] vnf_id The VNFD id
    put '/:vnf_id' do
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'

        catalogue, errors = ServiceConfigurationHelper.get_module('vnf_manager')
        halt 500, errors if errors

        begin
            response = RestClient.put catalogue.host + request.fullpath, request.body.read, 'X-Auth-Token' => catalogue.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'VNF Manager unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        return response.code, response.body
    end

    # @method delete_vnfs
    # @overload delete "/vnfs/:vnf_id"
    # Delete a VNFs
    # @param [string] vnf_id The VNFD id
    delete '/:vnf_id' do |vnf_id|
        # check if some NSD is using it
        ns_catalogue, errors = ServiceConfigurationHelper.get_module('ns_catalogue')
        halt 500, errors if errors

        catalogue.host, errors = ServiceConfigurationHelper.get_module('vnf_manager')
        halt 500, errors if errors

        begin
            response = RestClient.get ns_catalogue.host + '/network-services/vnf/' + vnf_id.to_s, 'X-Auth-Token' => ns_catalogue.token, :content_type => :json
            nss, errors = parse_json(response)
            unless nss.empty?
                halt 400, nss.size.to_s + ' Network Services are using this VNF.'
            end
        rescue Errno::ECONNREFUSED
            halt 500, 'NS Catalogue unreachable'
        rescue => e
            logger.error e.response
            # halt e.response.code, e.response.body
            logger.error 'Any network service is using this VNF.'
        end

        begin
            response = RestClient.delete catalogue.host + request.fullpath, 'X-Auth-Token' => catalogue.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'NS Catalogue unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        return response.code, response.body
    end
end
