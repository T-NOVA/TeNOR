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
    networks_name << create_provider_network(provider_info['allocated']['ce_transport'])
    networks_name << create_provider_network(provider_info['allocated']['pe_transport'])

    # Create the two networks
    2.times {networks_name << create_network}

    # Create the subnets for all networks
    networks_name.each_with_index {|name, index| create_subnet(name, 250 + index, nil)}
  
    # Create the Service Function Forwarder machine
    create_server('image_name', create_flavor, create_ports(networks_name, provider_info['security_group_id']))

    #puts @hot.to_yaml

    @hot
  end

  # Creates an HEAT port resource
  #
  # @param [Array] networks_name the name of the networks
  # @param [String] security_group_id the ID of the T-NOVA security group
  # @return [Array] a list of ports
  def create_ports(networks_name, security_group_id)
    ports = []

    networks_name.each do |network_name|
      port_name = get_resource_name
      ports << { port: {get_resource: port_name} }
      @hot.resources_list << Port.new(port_name, network_name, security_group_id)
    end

    ports
  end

  # Creates an HEAT flavor resource from the VNFD
  #
  # @return [String] the name of the created resource
  def create_flavor
    name = get_resource_name
    @hot.resources_list << Flavor.new(name, 20, 2048, 2)
    name
  end

  # Creates an HEAT server resource from the VNFD
  #
  # @param [Hash] vdu the VDU from the VNFD
  # @param [String] image_name the image resource name
  # @param [String] flavour_name the flavour resource name
  # @param [Array] ports list of the ports resource
  def create_server(image_name, flavour_name, ports)
    @hot.resources_list << Server.new(
      get_resource_name,
      {get_resource: flavour_name},
      image_name,
      ports,
      nil
    )
  end

  # Creates an HEAT provider netowork resource for the WICM
  #
  # @param [Hash] provider_info the provider network info
  def create_provider_network(provider_info)
    name = get_resource_name
    @hot.resources_list << ProviderNet.new(name, provider_info['type'], 'physical_network', provider_info['vlan_id'].to_s)
    name
  end

  # Creates an HEAT network resource from the NSD
  #
  # @param [String] public_net_id the public network id
  # @return [String] the name of the created resource
  def create_network
    name = get_resource_name
    @hot.resources_list << Network.new(name, name)
    name
  end

  # Creates an HEAT subnet resource from the NSD
  #
  # @param [String] network_name the network name
  # @param [String] cidr the CIDR for the network
  # @return [String] the name of the created subnet
  def create_subnet(network_name, index, dns_server)
    name = get_resource_name
    @hot.resources_list << Subnet.new(name, {get_resource: network_name}, dns_server, index)
    name
  end

  # Generates a new resource name
  #
  # @return [String] the generated resource name
  def get_resource_name
    @name + '_' + @hot.resources_list.length.to_s unless @name.empty?
  end

end