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
class Router < Resource

  # Initializes Router object
  #
  # @param [String] resource_name the Router resource name
  # @param [String] public_net_id the ID of the public network
  def initialize(resource_name, public_net_id, nsd_instance)
    @type = 'OS::Neutron::Router'
    @properties = {'external_gateway_info' => { 'network' => public_net_id }, 'name' => 'Tenor_' + nsd_instance.to_s}
    super(resource_name, @type, @properties)
  end
end