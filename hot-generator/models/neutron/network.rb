#
# TeNOR - HOT Generator
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
class Network < Resource

  # Initializes a Network object
  #
  # @param [String] resource_name the Network resource name
  # @param [String] name the name of the network
  # @param [String] shared if the network is shared
  # @param [String] port_security_enabled the security of the ports
  def initialize(resource_name, name, port_security_enabled = nil)
    type = 'OS::Neutron::Net'
    #port_security_enabled.nil?  ? properties = {'name' => name} : properties = {'name' => name, 'port_security_enabled' => port_security_enabled}
    properties = {'name' => name}
    super(resource_name, type, properties)
  end
end
