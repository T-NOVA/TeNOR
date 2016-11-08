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
# @see MapiHelper
module MapiHelper
    def registerRequestToMAPI(vnfr)
        logger.debug 'Registring VNF to mAPI...'

        # Send the VNFR to the mAPI
        mapi_request = { id: vnfr.id.to_s, vnfd: { vnf_lifecycle_events: vnfr.lifecycle_info } }
        logger.debug 'mAPI request: ' + mapi_request.to_json
        begin
            response = RestClient.post "#{settings.mapi}/vnf_api/", mapi_request.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            logger.error 'mAPI -> Connection Refused.'
            message = { status: 'mAPI_unreachable', vnfd_id: vnfr.vnfd_reference, vnfr_id: vnfr.id }
            logger.info 'mAPI is not reachable'
        rescue Errno::EHOSTUNREACH
            logger.error 'No route to mAPI host'
        rescue => e
            logger.error e
            message = { status: 'mAPI_error', vnfd_id: vnfr.vnfd_reference, vnfr_id: vnfr.id }
            logger.error message
            logger.info 'mAPI is not reachable'
        end
        logger.info 'Recevied response??'
        logger.info response
    end

    def sendCommandToMAPI(vnfr_id, mapi_request)
        logger.debug 'Sending command to mAPI...'
        # Send request to the mAPI
        begin
            if mapi_request[:event].casecmp('start').zero?
                response = RestClient.post "#{settings.mapi}/vnf_api/" + vnfr_id + '/config/', mapi_request.to_json, content_type: :json, accept: :json
            else
                response = RestClient.put "#{settings.mapi}/vnf_api/" + vnfr_id + '/config/', mapi_request.to_json, content_type: :json, accept: :json
            end
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return 500, 'mAPI unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end
        response
    end

    def sendDeleteCommandToMAPI(vnfr_id)
        logger.debug 'Sending remove command to mAPI...'
        begin
            response = RestClient.delete "#{settings.mapi}/vnf_api/#{vnfr_id}/"
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            # halt 500, 'mAPI unreachable'
            logger.error 'mAPI unrechable'
        rescue RestClient::ResourceNotFound
            logger.error 'Already removed from the mAPI.'
        rescue Errno::EHOSTUNREACH
            logger.error 'mAPI unrechable.'
        rescue => e
            logger.error 'Error removing vnfr from mAPI.'
            logger.error e
        end
    end
end
