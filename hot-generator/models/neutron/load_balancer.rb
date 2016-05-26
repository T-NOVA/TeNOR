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
class LoadBalancer < Resource

  # Initializes a LoadBalancer object
  #
  # @param [String] protocol_port the Protocol Port
  # @param [String] name the name of the network
  def initialize(resource_name, protocol_port, pool_id, members)
    @type = 'OS::Neutron::LoadBalancer'
    #@properties = {'name' => name, 'save_private_key' => true, 'vip_subnet' => vip_subnet, 'admin_state_up' => true}
    @properties = {'protocol_port' => protocol_port, 'pool_id' => pool_id, 'members' => members}
    super(resource_name, @type, @properties)
  end
end
