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
  def build(chains, odl_username, odl_password, netfloc_ip_port)

    chains.each do |chain|
      create_chains(chain, odl_username, odl_password, netfloc_ip_port)
    end

#    puts @hot.to_yaml

    @hot
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
