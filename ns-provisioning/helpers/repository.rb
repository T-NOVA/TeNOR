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
# @see OrchestratorNsProvisioner
class OrchestratorNsProvisioner < Sinatra::Application

  def createInstance(instance)
    begin
      response = RestClient.post settings.ns_instance_repository + '/ns-instances', instance.to_json, :content_type => :json
    rescue Errno::ECONNREFUSED
      logger.error 'NS Instance repository unreachable'
      #  halt 500, 'NS Instance repository unreachable'
      raise 'NS Instance repository unreachable'
    rescue => e
      logger.error e.response
      raise e.response
      #return { :code => e.response.code, :body => e.response.body}
    end
    instance, error = parse_json(response)
    return instance
  end

  def updateInstance(instance)
    begin
      response = RestClient.put settings.ns_instance_repository + '/ns-instances/' + instance['id'].to_s, instance.to_json, :content_type => :json
    rescue Errno::ECONNREFUSED
      logger.error 'NS Instance repository unreachable'
      raise 'NS Instance repository unreachable'
    rescue => e
      logger.error e.response
      raise e.response
      #return { :code => e.response.code, :body => e.response.body}
    end
    instance, error = parse_json(response)
    return instance
  end

  def removeInstance(instance)
    begin
      RestClient.delete settings.ns_instance_repository + '/ns-instances/' + instance['id'].to_s
    rescue Errno::ECONNREFUSED
      logger.error 'NS Instance repository unreachable'
      raise 'NS Instance repository unreachable'
    rescue => e
      logger.error e.response
      raise "Remove instance error"
      #return { :code => e.response.code, :body => e.response.body}
    end
    halt 200, "Removed correctly"
  end

end