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
# @see HotHelper
module HotHelper
    def deleteStack(stack_url, auth_token)
        response = RestClient.delete stack_url, 'X-Auth-Token' => auth_token, :accept => :json
    rescue Errno::ECONNREFUSED
    # halt 500, 'VIM unreachable'
    rescue RestClient::ResourceNotFound
        logger.error 'Already removed from the VIM.'
        return 404
    rescue => e
        logger.error e.response
        return
    end

    def getStackResources(stack_url, auth_token)
        begin
            response = RestClient.get stack_url + '/resources', 'X-Auth-Token' => auth_token
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            return
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            return
        end
        resources, errors = parse_json(response)
        return 400, errors if errors

        resources['resources']
    end

    def delete_stack_with_wait(stack_url, auth_token)
        status = 'DELETING'
        count = 0
        code = deleteStack(stack_url, auth_token)
        if code == 404
            status = 'DELETE_COMPLETE'
            return 200
        end
        while status != 'DELETE_COMPLETE' && status != 'DELETE_FAILED'
            sleep(5)
            begin
                response = RestClient.get stack_url, 'X-Auth-Token' => auth_token, :content_type => :json, :accept => :json
                stack_info, error = parse_json(response)
                status = stack_info['stack']['stack_status']
            rescue Errno::ECONNREFUSED
                error = { 'info' => 'VIM unrechable.' }
                return
            rescue RestClient::ResourceNotFound
                logger.info 'Stack already removed.'
                status = 'DELETE_COMPLETE'
            rescue => e
                puts 'If no exists means that is deleted correctly'
                status = 'DELETE_COMPLETE'
                logger.error e
                logger.error e.response
            end

            logger.debug 'Try: ' + count.to_s + ', status: ' + status.to_s
            if status == 'DELETE_FAILED'
                deleteStack(stack_url, auth_token)
                status = 'DELETING'
            end
            break if status == 'DELETE_COMPLETE'
            count += 1

            if count > 20
                logger.error 'Stack can not be removed'
                return 400, 'Stack can not be removed'
            end
        end
        response
    end
end
