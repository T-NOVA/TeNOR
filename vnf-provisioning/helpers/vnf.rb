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
# @see OrchestratorVnfProvisioning
class OrchestratorVnfProvisioning < Sinatra::Application

  # Checks if a JSON message is valid
  #
  # @param [JSON] message some JSON message
  # @return [Hash] the parsed message
  def parse_json(message)
    # Check JSON message format
    begin
      parsed_message = JSON.parse(message) # parse json message
    rescue JSON::ParserError => e
      # If JSON not valid, return with errors
      logger.error "JSON parsing: #{e.to_s}"
      halt 400, e.to_s + "\n"
    end

    parsed_message
  end

  # Method which lists all available interfaces
  #
  # @return [Array] an array of hashes containing all interfaces
  def interfaces_list
    [
        {
            uri: '/',
            method: 'GET',
            purpose: 'REST API Structure and Capability Discovery'
        },
        {
            uri: '/vnf-provisioning/vnf-instances',
            method: 'POST',
            purpose: 'Provision a VNF'
        },
        {
            uri: '/vnf-provisioning/vnf-instances/:id/destroy',
            method: 'POST',
            purpose: 'Destroy a VNF'
        }
    ]
  end

  # Request an auth token from the VIM
  #
  # @param [Hash] auth_info the keystone url, the tenant name, the username and the password
  # @return [Hash] the auth token and the tenant id
  def request_auth_token(vim_info)
    # Build request message
    request = {
      auth: {
        tenantName: vim_info['tenant'],
        passwordCredentials: {
          username: vim_info['username'],
          password: vim_info['password']
        }
      }
    }

    # GET auth token
    begin
      response = RestClient.post "#{vim_info['keystone']}/tokens", request.to_json, :content_type => :json, :accept => :json
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    parse_json(response)
  end

  # Provision a VNF
  #
  # @param [Hash] auth_info the keystone url, the tenant name, the username and the password
  # @param [String] heat_url the Heat API URL
  # @param [String] vnf_name The name of the VNF
  # @param [Hash] hot the generated Heat template
  def provision_vnf(vim_info, vnf_name, hot)
    # Request an auth token
    token_info = request_auth_token(vim_info)
    tenant_id = token_info['access']['token']['tenant']['id']
    auth_token = token_info['access']['token']['id']

    # Requests VIM to provision the VNF
    begin
      response = parse_json(RestClient.post "#{vim_info['heat']}/#{tenant_id}/stacks", {stack_name: vnf_name, template: hot}.to_json , 'X-Auth-Token' => auth_token, :content_type => :json, :accept => :json)
    rescue Errno::ECONNREFUSED
      halt 500, 'VIM unreachable'
    rescue => e
      logger.error e.response
      halt e.response.code, e.response.body
    end

    response
  end

  # Monitor stack state
  #
  # @param [String] url the HEAT URL for the stack
  # @param [String] auth_token the auth token to authenticate with the VIM
  def create_thread_to_monitor_stack(vnfr_id, stack_url, vim_info, ns_manager_callback)
    # Check when stack change state
    thread = Thread.new do 
      sleep_time = 10 # set wait time in seconds

      begin
        # Request an auth token
        token_info = request_auth_token(vim_info)
        auth_token = token_info['access']['token']['id']

        begin          
          response = parse_json(RestClient.get stack_url, 'X-Auth-Token' => auth_token, :accept => :json)
        rescue Errno::ECONNREFUSED
          halt 500, 'VIM unreachable'
        rescue => e
          logger.error e.response
        end

        sleep sleep_time # wait x seconds

      end while response['stack']['stack_status'].downcase == 'create_in_progress'

      # After stack create is complete, send information back to provisioning
      response[:ns_manager_callback] = ns_manager_callback
      response[:vim_info] = vim_info # Needed to delete the stack if it failed
      begin
        RestClient.post "http://localhost:#{settings.port}/vnf-provisioning/#{vnfr_id}/stack/#{response['stack']['stack_status'].downcase}", response.to_json, :content_type => :json
      rescue Errno::ECONNREFUSED
        halt 500, 'VNF Provisioning unreachable'
      rescue => e
        logger.error e.response
      end
    end
  end

end