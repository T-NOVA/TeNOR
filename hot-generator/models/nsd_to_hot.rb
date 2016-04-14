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
  # @param [Hash] nsd the NSD
  # @param [String] public_net_id the ID of the public network
  # @param [String] dns_server the DNS Server to add to the networks
  # @param [String] flavour the T-NOVA flavour
  # @return [HOT] returns an HOT object
  def build(nsd, public_net_id, dns_server, flavour)
    router_name = create_router(public_net_id)
    
    virtual_links = nsd['vld']['virtual_links']
    nsd['vld']['virtual_links'].each_with_index do |vlink, index|
      if vlink['sla_ref_id'] == flavour
        if (vlink['merge'])
          #TODO
          #use the same network
        end
        vlink['connections'].each do |link, index2|
          network_name = create_network(link.split(":ext_")[1])
          subnet_name = create_subnet(network_name, dns_server, index, index2)
          create_router_interface(router_name, subnet_name)
        end
      end
    end

    #puts @hot.to_yaml

    @hot
  end

  # Creates an HEAT router resource from the NSD
  #
  # @param [String] public_net_id the ID of the public network
  # @return [String] the name of the created resource
  def create_router(public_net_id)
    name = get_resource_name
    @hot.resources_list << Router.new(name, public_net_id)
    name
  end

  # Creates an HEAT network resource from the NSD
  #
  # @param [String] network_name the network name
  # @return [String] the name of the created resource
  def create_network(network_name)
    name = get_resource_name
    @hot.resources_list << Network.new(name, network_name)
    name
  end

  # Creates an HEAT subnet resource from the NSD
  #
  # @param [String] network_name the network name
  # @param [String] dns_server the DNS server to use
  # @param [Integer] index the id used for the CIDR
  # @return [String] the name of the created resource
  def create_subnet(network_name, dns_server, index, index2)
    name = get_resource_name
    @hot.resources_list << Subnet.new(name,  {get_resource: network_name}, dns_server, index, index2)
    name
  end

  # Creates a Router interface
  #
  # @param [String] router_name the router name
  # @param [String] subnet_name the subnet name
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