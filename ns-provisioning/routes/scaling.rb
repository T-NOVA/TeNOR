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
# @see NsProvisioner
class Scaling < NsProvisioning
    # @method post_ns_instances_scale_out
    # @overload post '/ns-instances/scaling/:id/scale_out'
    # Post a Scale out request
    # @param [JSON]
    post '/:id/scale_out' do |id|
        halt 415 unless request.content_type == 'application/json'

        begin
            instance = Nsr.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt(404)
        end

        instance['vnfrs'].each do |vnf|
            logger.info 'Scale out VNF ' + vnf['vnfr_id'].to_s + ' into Pop_id: ' + vnf['pop_id'].to_s
            raise 'VNF not defined' if vnf['pop_id'].nil?

            pop_auth = instance['authentication'].find { |pop| pop['pop_id'] == vnf['pop_id'] }
            pop_urls = pop_auth['urls']

            credentials, errors = authenticate(pop_urls[:keystone], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'])
            logger.error errors if errors
            return if errors
            scale = { auth: { tenant_id: credentials[:tenant_id], user_id: credentials[:user_id], token: credentials[:token], url: { keystone: pop_urls[:keystone], heat: pop_urls[:heat] } }}

            begin
                response = RestClient.post settings.vnf_manager + '/vnf-instances/scaling/' + vnf['vnfr_id'] + '/scale_out', scale.to_json, content_type: :json
            rescue => e
                logger.error e
            end

            logger.debug response
        end
        halt 200, 'Scale out done.'
    end

    # @method post_ns_instances_scale_in
    # @overload post '/ns-instances/scaling/:id/scale_in'
    # Post a Scale in request
    # @param [JSON]
    post '/:id/scale_in' do |id|
        halt 415 unless request.content_type == 'application/json'

        begin
            instance = Nsr.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            halt(404)
        end

        instance['vnfrs'].each do |vnf|
            logger.info 'Scale in VNF ' + vnf['vnfr_id'].to_s + ' into Pop_id: ' + vnf['pop_id'].to_s
            raise 'VNF not defined' if vnf['pop_id'].nil?

            pop_auth = instance['authentication'].find { |pop| pop['pop_id'] == vnf['pop_id'] }
            pop_urls = pop_auth['urls']

            credentials, errors = authenticate(pop_urls[:keystone], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'])
            logger.error errors if errors
            return if errors
            scale = { auth: { tenant_id: credentials[:tenant_id], user_id: credentials[:user_id], token: credentials[:token], url: { keystone: pop_urls[:keystone], heat: pop_urls[:heat] } }}

            begin
                response = RestClient.post settings.vnf_manager + '/vnf-instances/scaling/' + vnf['vnfr_id'] + '/scale_in', scale.to_json, content_type: :json
            rescue => e
                logger.error e
            end

            logger.debug response
        end
        halt 200, 'Scale in done.'
    end
end
