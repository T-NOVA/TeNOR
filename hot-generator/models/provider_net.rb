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
class ProviderNet < Resource

  # Initializes Provider Network object
  #
  # @param [String] resource_name the Subnet resource name
  # @param [String] network_type the provider network type for the network
  # @param [String] physical_network the physical network mapping for the network
  # @param [String] segmentation_id the segmentation id for the network
  def initialize(resource_name, network_type, physical_network, segmentation_id)
    @type = 'OS::Neutron::ProviderNet'
    @properties = {'network_type' => network_type, 'physical_network' => physical_network, 'segmentation_id' => segmentation_id}
    super(resource_name, @type, @properties)
  end
end