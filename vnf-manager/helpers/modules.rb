#
# TeNOR - VNF Manager
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
          ip = ip.split("@")[1] if ip.include? "@"
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
  
  def self.get_module(name)
    begin
      service = Service.find_by(name: name)
    rescue Mongoid::Errors::DocumentNotFound => e
      return 500, name + " not registred."
    end
    service.host = service.host + ":" + service.port.to_s
    service
  end
end
