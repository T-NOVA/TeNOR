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
class NetflocToHot

  # Initializes NetflocToHot object
  #
  # @param [String] name the name for the HOT
  # @param [String] description the description for the HOT
  def initialize(name, description)
    @hot = Hot.new(description)
    @name = name
  end

  # Create a Netfloc HOT
  #
  # @param [Hash] vnffgd
  # @return [HOT] returns an HOT object
  def build(ports, odl_username, odl_password, netfloc_ip_port)

    create_chains(ports, odl_username, odl_password, netfloc_ip_port)

    puts @hot.to_yaml

    @hot
=begin
    #for each create a chain

    puts reserved_resources.to_json

    chain_ports = []

    vnffgd['vnffgs'].each do |fg|
      fg['network_forwarding_path'].each do |path|
        path['connection_points'].each do |port|
          #find resource array where is located the
          resource = reserved_resources.find { |resource| resource['ports'].find { |p| p['ns_network'] == port } }
          vnf_port = resource['ports'].find { |p| p['ns_network'] == port }
          puts port
          puts vnf_port["vnf_ports"][0]['physical_resource_id']
          #{"ns_network"=>"VNF#2372:ext_itl-mng", "vnf_ports"=>[{"id"=>"CPkkyz", "vlink_ref"=>"vl0", "physical_resource_id"=>"71895665-2a8d-421b-92ae-7b6ea7eb2371"}, {"id"=>"CPtmsr", "vlink_ref"=>"vl0", "physical_resource_id"=>"fb147a46-d83d-4ea8-aad8-7208c1f2f7d8"}]}

          #map port_name to openstack_port_id
          chain_ports << vnf_port["vnf_ports"][0]['physical_resource_id']
        end
      end
      create_chain(chain_ports, odl_username, odl_password, netfloc_ip_port)
    end

    puts @hot.to_yaml

    @hot
=end
  end

  # Creates an HEAT Netfloc chain resource
  #
  # @return [String] the name of the created resource
  def create_chains(ports, odl_username, odl_password, netfloc_ip_port)
    name = get_resource_name
    @hot.resources_list << Chain.new(name, ports, odl_username, odl_password, netfloc_ip_port)
    name
  end

  # Generates a new resource name
  #
  # @return [String] the generated resource name
  def get_resource_name
    @name + '_' + @hot.resources_list.length.to_s unless @name.empty?
  end

end
