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
class NsdToHot

  # Initializes NetworkToHot object
  #
  # @param [String] name the name for the HOT
  # @param [String] description the description for the HOT
  def initialize(name, description)
    @hot = Hot.new(description)
    @name = name
    @outputs = {}
  end

  # Converts NSD to Network HOT
  #
  # @param [Hash] vnfd the VNFD
  # @param [String] tnova_flavour the T-NOVA flavour to generate the HOT for
  # @param [Array] networks_id the IDs of the networks created by NS Manager
  # @param [String] security_group_id the ID of the T-NOVA security group
  # @return [HOT] returns an HOT object
  def build(nsd, public_net_id, dns_server, flavour)

    router_name = create_router(public_net_id)
    virtual_links = nsd['vld']['virtual_links']
    nsd['vld']['virtual_links'].each_with_index do |vlink, index|
      if vlink['flavor_ref_id'] == flavour
        if (vlink['merge'])
          #TODO
          #use the same network
        end
        #network_name = create_network(vlink['alias'])
        vlink['connections'].each do |link|
          network_name = create_network(link.split(":ext_")[1])
          subnet_name = create_subnet(network_name, dns_server, index)
          create_router_interface(router_name, subnet_name)
        end
      end
    end

    #puts @hot.to_yaml

    @hot
  end

  # Creates an HEAT router resource from the NSD
  #
  # @param [String] public_net_id the public network id
  # @return [String] the name of the created resource
  def create_router(public_net_id)
    name = get_resource_name
    @hot.resources_list << Router.new(name, public_net_id)
    name
  end

  # Creates an HEAT network resource from the NSD
  #
  # @param [String] public_net_id the public network id
  # @return [String] the name of the created resource
  def create_network(network_name)
    name = get_resource_name
    @hot.resources_list << Network.new(name, network_name)
    name
  end

  # Creates an HEAT subnet resource from the NSD
  #
  # @param [network_name] network_name the network name
  # @param [index] index the id used for the CIDR
  # @return [String] the name of the created resource
  def create_subnet(network_name, dns_server, index)
    name = get_resource_name
    @hot.resources_list << Subnet.new(name,  {get_resource: network_name}, dns_server, index)
    name
  end

  # Creates an HEAT subnet resource from the NSD
  #
  # @param [router_name] router_name the router name
  # @param [subnet_name] subnet_name the subnet name
  # @return [String] the name of the created resource
  def create_router_interface(router_name, subnet_name)
    name = get_resource_name
    @hot.resources_list << RouterInterface.new(name, {get_resource: router_name}, {get_resource: subnet_name})
    name
  end

  # Generates a new resource name
  #
  # @return [String] the generated resource name
  def get_resource_name
    @name + '_' + @hot.resources_list.length.to_s unless @name.empty?
  end

end