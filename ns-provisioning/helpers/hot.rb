#
# TeNOR - NS Provisioning
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
#
# @see NSProvisioner
module HotHelper
    def generateNetworkHotTemplate(sla_id, hot_generator_message)
        begin
            response = RestClient.post settings.hot_generator + "/networkhot/#{sla_id}", hot_generator_message.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'HOT Generator unrechable.' }
            return 500, error
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error 'E IS NIL' if e.nil?
            logger.error 'RESPONSE IS NIL?' if e.response.nil?
            # logger.error e.response
            return 500, e
        end
        hot, errors = parse_json(response)
        return 400, errors if errors

        hot
    end

    def generateWicmHotTemplate(provider_info)
        begin
            response = RestClient.post settings.hot_generator + '/wicmhot', provider_info.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'HOT Generator unreachable.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        end
        hot, errors = parse_json(response)
        return 400, errors if errors

        hot
    end

    def sendStack(url, tenant_id, template, tenant_token)
        begin
            response = RestClient.post "#{url}/#{tenant_id}/stacks", template.to_json, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            return 500, error
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response
            logger.error e.response.body if e.response
            error = { 'info' => 'Error creating the network stack.' }
            return 500, error
        end
        stack, errors = parse_json(response)
        return 400, errors if errors

        stack
    end

    def getStackInfo(url, tenant_id, name, tenant_token)
        begin
            response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}", 'X-Auth-Token' => tenant_token
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        end
        stack_info, errors = parse_json(response)
        return 400, errors if errors

        stack_info
    end

    def getStackResources(url, tenant_id, name, tenant_token)
        begin
            response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}/resources", 'X-Auth-Token' => tenant_token
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        end
        network_resources, errors = parse_json(response)
        return 400, errors if errors

        network_resources
    end

    def getStackResource(url, tenant_id, name, stack_id, resource_name, tenant_token)
        begin
            response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}/#{stack_id}/resources/#{resource_name}", 'X-Auth-Token' => tenant_token
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'VIM unrechable.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error e.response
            error = { 'info' => 'Error creating the network stack.' }
            recoverState(popInfo, vnf_info, @instance, error)
            return
        end
        resources, errors = parse_json(response)
        return 400, errors if errors

        resources
    end

    def deleteStack(stack_url, tenant_token)
        response = RestClient.delete stack_url, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
      rescue Errno::ECONNREFUSED
          error = { 'info' => 'VIM unrechable.' }
          return
      rescue RestClient::ResourceNotFound
          logger.error 'Already removed from the VIM.'
          return 404
      rescue => e
          logger.error e
          logger.error e.response
          return
      end

    def generateNetflocTemplate(hot_generator_message)
        begin
            response = RestClient.post settings.hot_generator + '/netfloc', hot_generator_message.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'HOT Generator unrechable.' }
            return 500, error
        rescue => e
            puts e
            logger.error e.response
            return 500, e
        end
        hot, errors = parse_json(response)
        return 400, errors if errors

        hot
    end

    def create_stack_wait(orch_url, tenant_id, stack_name, tenant_token, type)
        status = 'CREATING'
        count = 0
        while status != 'CREATE_COMPLETE' && status != 'CREATE_FAILED'
            sleep(5)
            stack_info, errors = getStackInfo(orch_url, tenant_id, stack_name, tenant_token)
            status = stack_info['stack']['stack_status']
            count += 1
            break if count > 10
        end
        if status == 'CREATE_FAILED'
            error = 'Error creating the stack: ' + type
            logger.error error
            logger.error stack_info
            logger.error errors
            @instance.push(lifecycle_event_history: 'ERROR_CREATING the ' + type)
            @instance.update_attribute('status', 'ERROR_CREATING')
            @instance.push(audit_log: stack_info)
            logger.error 'Creation of Network Stack failed.'
            return 400, error
        elsif status == 'CREATE_COMPLETE'
            return stack_info
        end
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

    def generateUserHotTemplate(hot_generator_message)
        begin
            response = RestClient.post settings.hot_generator + '/userhot', hot_generator_message.to_json, content_type: :json, accept: :json
        rescue Errno::ECONNREFUSED
            error = { 'info' => 'HOT Generator unrechable.' }
            return 500, error
        rescue RestClient::ExceptionWithResponse => e
            logger.error e
            logger.error e.response.body
            return e.response.code, e.response.body
        rescue => e
            logger.error e
            logger.error 'E IS NIL' if e.nil?
            logger.error 'RESPONSE IS NIL?' if e.response.nil?
            # logger.error e.response
            return 500, e
        end
        hot, errors = parse_json(response)
        return 400, errors if errors

        hot
    end
end
