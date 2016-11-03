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
# @see ServiceConfigurationHelper
module ServiceConfigurationHelper
  def is_port_open?(ip, port)
	  begin
		Timeout::timeout(1) do
      begin
          s = TCPSocket.new(ip, port)
		      s.close
          return true
		  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
		    return false
      end
	  end
	  rescue Timeout::Error
	  end
	  return false
  end

  def self.get_module_by_id(id)
    begin
      s = Service.find(id)
    rescue Mongoid::Errors::DocumentNotFound => e
      return 500, name + " not registred."
    end
    s
  end

  def self.get_module(name)
    begin
      s = Service.find_by(name: name)
    rescue Mongoid::Errors::DocumentNotFound => e
      return 500, name + " not registred."
    end
    s.host = s.host + ":" + s.port.to_s
    s
  end

  def self.get_module_by_type(type)
    begin
      s = Service.find_by(type: type)
    rescue Mongoid::Errors::DocumentNotFound => e
      return 500, name + " not registred."
    end
    s.host + ":" + s.port.to_s
  end





  def self.publishServices
    services = getServices()
    services.each do |service|
      logger.debug "Sending dependencies to " + service['name']
      if service['type'] == "internal"
        begin
          RestClient.post service['host'] + ":" + service['port'] + "/gk_dependencies", services.to_json, :content_type => :json
        rescue => e
          #logger.error e
          #puts e
          #halt 500, {'Content-Type' => 'text/plain'}, "Error sending dependencies to " +service['name']
        end
      end
    end
  end

  def self.publishService(name)
    services = getServices
    service = getService(name)
    begin
      RestClient.post service['host'] + ":" + service['port'] + "/gk_dependencies", services.to_json, :content_type => :json
    rescue => e
      #logger.error e
      puts e
      #halt 500, {'Content-Type' => 'text/plain'}, "Error sending dependencies to " +service['name']
    end

  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= TnovaManager.logger
  end
end
