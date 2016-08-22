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
      response = RestClient.post settings.hot_generator + "/networkhot/#{sla_id}", hot_generator_message.to_json, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      error = {"info" => "HOT Generator unrechable."}
      return 500, error
    rescue => e
      puts e
      logger.error e.response
      return 500, e
    end
    hot, errors = parse_json(response)
    return 400, errors if errors

    return hot
  end

  def generateWicmHotTemplate(provider_info)
    begin
      response = RestClient.post settings.hot_generator + '/wicmhot', provider_info.to_json, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      error = {"info" => "HOT Generator unreachable."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    rescue => e
      logger.error e
      logger.error e.response
      error = {"info" => "Error creating the network stack."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    end
    hot, errors = parse_json(response)
    return 400, errors if errors

    return hot
  end

  def sendStack(url, tenant_id, template, tenant_token)
    begin
      response = RestClient.post "#{url}/#{tenant_id}/stacks", template.to_json, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      error = {"info" => "VIM unrechable."}
      return 500, error
    rescue => e
      logger.error e
      error = {"info" => "Error creating the network stack."}
      return 500, error
    end
    stack, errors = parse_json(response)
    return 400, errors if errors

    return stack
  end

  def getStackInfo(url, tenant_id, name, tenant_token)
    begin
      response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}", 'X-Auth-Token' => tenant_token
    rescue Errno::ECONNREFUSED
      error = {"info" => "VIM unrechable."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    rescue => e
      logger.error e
      logger.error e.response
      error = {"info" => "Error creating the network stack."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    end
    stack_info, errors = parse_json(response)
    return 400, errors if errors

    return stack_info
    status = stack_info['stack']['stack_status']
  end

  def getStackResources(url, tenant_id, name, tenant_token)
    begin
      response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}/resources", 'X-Auth-Token' => tenant_token
    rescue Errno::ECONNREFUSED
      error = {"info" => "VIM unrechable."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    rescue => e
      logger.error e
      logger.error e.response
      error = {"info" => "Error creating the network stack."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    end
    network_resources, errors = parse_json(response)
    return 400, errors if errors

    return network_resources
  end

  def getStackResource(url, tenant_id, name, stack_id, resource_name, tenant_token)
    begin
      response = RestClient.get "#{url}/#{tenant_id}/stacks/#{name}/#{stack_id}/resources/#{resource_name}", 'X-Auth-Token' => tenant_token
    rescue Errno::ECONNREFUSED
      error = {"info" => "VIM unrechable."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    rescue => e
      logger.error e
      logger.error e.response
      error = {"info" => "Error creating the network stack."}
      recoverState(popInfo, vnf_info, @instance, error)
      return
    end
    resources, errors = parse_json(response)
    return 400, errors if errors

    return resources
  end

  def deleteStack(stack_url, tenant_token)
    begin
      response = RestClient.delete stack_url, 'X-Auth-Token' => tenant_token, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      error = {"info" => "VIM unrechable."}
      return
    rescue => e
      logger.error e
      logger.error e.response
      return
    end
  end

end