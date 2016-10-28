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
# @see NSProvisioner
module AuthenticationHelper

  def authenticate(keystone_url, tenant_name, username, password)
    keystone_version = URI(keystone_url).path.split('/').last
    if keystone_version == 'v2.0'
      user_authentication, errors = authentication_v2(keystone_url, tenant_name, username, password)
      logger.error errors if errors
      return 400, errors.to_json if errors
      tenant_id = user_authentication['access']['token']['tenant']['id']
      user_id = user_authentication['access']['user']['id']
      token = user_authentication['access']['token']['id']
    elsif keystone_version == 'v3'
        user_authentication, errors = authentication_v3(keystone_url, tenant_name, username, password)
        logger.error errors if errors
        return 400, errors.to_json if errors
        if !user_authentication['token']['project'].nil?
            tenant_id = user_authentication['token']['project']['id']
            user_id = user_authentication['token']['user']['id']
            token = user_authentication['token']['id']
        else
            errors = "No project found with the authentication."
            return 400, errors.to_json if errors
        end
    end
    {:tenant_id => tenant_id, :user_id => user_id, :token => token}
  end

  def create_user_and_project(heat_api, instance_id, project_name, username, password, tenant_id, token)
    generated_credentials = {}
    generated_credentials['password'] = password
    generated_credentials['tenant_name'] = project_name
    generated_credentials['username'] = username

    hot_generator_message = {
      project_name: generated_credentials['tenant_name'],
      username: generated_credentials['username'],
      password: generated_credentials['password'],
      domain: nil
    }

    logger.info 'Generating user HOT template...'
    hot, errors = generateUserHotTemplate(hot_generator_message)
    return handleError(@instance, errors) if errors

    logger.info 'Send user template to HEAT Orchestration'
    stack_name = 'user_' + @instance['id'].to_s
    template = { stack_name: stack_name, template: hot }
    stack, errors = sendStack(heat_api, tenant_id, template, token)
    return handleError(@instance, errors) if errors
    stack_id = stack['stack']['id']
    stack_url = stack['stack']['links'][0]['href']

    logger.info 'Checking user stack creation...'
    stack_info, errors = create_stack_wait(heat_api, tenant_id, stack_name, token, 'NS User')
    return handleError(@instance, errors) if errors

    logger.info 'User stack CREATE_COMPLETE. Reading user information from stack...'
    sleep(3)
    stack_info, errors = getStackInfo(heat_api, tenant_id, stack_name, token)
    return handleError(@instance, errors) if errors
    tenant_id = stack_info['stack']['outputs'].find{ |res| res['output_key'] == 'project_id' }['output_value']
    user_id = stack_info['stack']['outputs'].find{ |res| res['output_key'] == 'user_id' }['output_value']

    return stack_url, tenant_id, user_id
  end

end
