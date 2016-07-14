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
class WicmToHot

  # Initializes WicmToHot object
  #
  # @param [String] name the name for the HOT
  # @param [String] description the description for the HOT
  def initialize(name, description)
    @hot = Hot.new(description)
    @name = name
  end

  # Create a WICM HOT
  #
  # @param [Hash] provider_info information about the VLANs
  # @return [HOT] returns an HOT object
  def build(provider_info)

    # Create the two provider networks
    networks_name = []
    networks_name << create_provider_network(provider_info['allocated']['ce_transport'], provider_info['physical_network'])
    networks_name << create_provider_network(provider_info['allocated']['pe_transport'], provider_info['physical_network'])

    # Create the two networks
    2.times {networks_name << create_network}

    # Create the subnets for all networks
    networks_name.each_with_index {|name, index| create_subnet(name, 250 + index, '8.8.8.8')}

    # Create the Service Function Forwarder machine
    create_server('image_name', create_flavor, create_ports(networks_name))

    #puts @hot.to_yaml

    @hot
  end



end