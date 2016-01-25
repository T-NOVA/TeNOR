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
class FloatingIpAssociation < Resource

	# Initializes FloatingIpAssociation object
	#
	# @param [String] resource_name the FloatingIpAssociation resource name
	# @param [String] floatingip_id ID of the Floating IP to associate
	# @param [String] port_id ID of an existing port to associate with this floating IP
	def initialize(resource_name, floatingip_id, port_id)
		type = 'OS::Neutron::FloatingIPAssociation'
		properties = {'floatingip_id' => floatingip_id, 'port_id' => port_id}
		super(resource_name, type, properties)
	end
end