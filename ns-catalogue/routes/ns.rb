#
# TeNOR - NS Catalogue
#
# Copyright 2014-2016 i2CAT Foundation
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
# @see NsCatalogue
class Catalogue < NsCatalogue
    # @method get_network_services
    # @overload get '/network-services'
    # Returns a list of NSs
    get '/' do
        params[:offset] ||= 1
        params[:limit] ||= 20

        # Only accept positive numbers
        params[:offset] = 1 if params[:offset].to_i < 1
        params[:limit] = 2 if params[:limit].to_i < 1

        # Get paginated list
        nss = Ns.paginate(page: params[:offset], limit: params[:limit])

        # Build HTTP Link Header
        headers['Link'] = build_http_link(params[:offset].to_i, params[:limit])

        begin
            return 200, nss.to_json
        rescue
            logger.error 'Error Establishing a Database Connection'
            return 500, 'Error Establishing a Database Connection'
        end
    end

    # @method get_network_services_id
    # @overload get '/network-services/:external_ns_id'
    #	Show a NS
    #	@param [Integer] external_ns_id NS external ID
    get '/:id' do |id|
        begin
            ns = Ns.find_by('nsd.id' => id)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'NSD not found.'
            halt 404
        end
        return 200, ns.nsd.to_json
        # NsSerializer.new(ns).to_json
    end

    # @method post_network_services
    # @overload post '/network-services'
    # Post a NS in JSON format
    # @param [JSON] NS in JSON format
    post '/' do
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'

        # Validate JSON format
        ns, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        # Validate NS
        return 400, 'ERROR: NSD not found' unless ns.key?('nsd')

        # Validate NSD
        begin
            RestClient.post settings.nsd_validator + '/nsds', ns.to_json, content_type: :json, 'X-Auth-Token' => settings.nsd_validator_token
        rescue Errno::ECONNREFUSED
            logger.error 'NSD Validator unreachable'
            halt 500, 'NSD Validator unreachable'
        rescue => e
            logger.error e
            halt e.response.code, e.response.body
        end

        begin
            ns = Ns.find_by('nsd.id' => ns['nsd']['id'], 'nsd.version' => ns['nsd']['version'], 'nsd.vendor' => ns['nsd']['vendor'])
            logger.error ns
            unless ns.nil?
                logger.error 'ERROR: Duplicated NS ID, Version or Vendor'
                return 409, 'ERROR: Duplicated NS ID, Version or Vendor'
            end
        rescue Mongoid::Errors::DocumentNotFound => e
        end

        # Save to BD
        begin
            new_ns = Ns.create!(ns)
        rescue Moped::Errors::OperationFailure => e
            return 400, 'ERROR: Duplicated NS ID' if e.message.include? 'E11000'
        rescue => e
            logger.error 'Some other error.'
            logger.error e
        end

        return 201, new_ns.to_json
    end

    # @method put_nss
    # @overload put '/network-services/:id'
    # Update a NS
    # @param [JSON] NS in JSON format
    put '/:external_ns_id' do
        # Return if content-type is invalid
        return 415 unless request.content_type == 'application/json'

        # Validate JSON format
        new_ns, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        begin
            ns = Ns.find_by('nsd.id' => params[:external_ns_id])
        rescue Mongoid::Errors::DocumentNotFound => e
            return 400, 'This NSD no exists'
        end

        nsd = {}
        prng = Random.new
        new_ns['id'] = new_ns['id'] + prng.rand(1000).to_s
        nsd['nsd'] = new_ns

        # Validate NSD
        begin
            RestClient.post settings.nsd_validator + '/nsds', nsd.to_json, content_type: :json, 'X-Auth-Token' => settings.nsd_validator_token
        rescue => e
            logger.error e.response
            return e.response.code, e.response.body
        end

        begin
            new_ns = Ns.create!(nsd)
        rescue Moped::Errors::OperationFailure => e
            return 400, 'ERROR: Duplicated NS ID' if e.message.include? 'E11000'
        end

        return 200, new_ns.to_json
    end

    # @method delete_ns_id
    # @overload delete '/network-services/:external_vnf_id'
    #	Delete a NS by its ID
    #	@param [Integer] external_ns_id NS external ID
    delete '/:external_ns_id' do
        begin
            # ns = Ns.find( params[:external_ns_id] )
            ns = Ns.find_by('nsd.id' => params[:external_ns_id])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404
        end
        ns.destroy
        return 200
    end

    get '/vnf/:vnf_id' do
        begin
            nss = Ns.find_by('nsd.vnfds' => params[:vnf_id])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 404, 'No services using this VNFD'
        end
        return 200, nss.to_json
    end
end
