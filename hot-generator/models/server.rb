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
class Server < Resource

	# Initializes Server object
	#
	# @param [String] resource_name the Server resource name
	# @param [String] flavor the ID or name of the flavor to boot onto
	# @param [String] image the ID or name of the image to boot with
	# @param [Array] networks a list of ports ID to be added to this server
	def initialize(resource_name, flavor, image, networks)
		type = 'OS::Nova::Server'
		properties = {'flavor' => flavor, 'image' => image, 'networks' => networks}
		super(resource_name, type, properties)
	end
end