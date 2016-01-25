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
class Resource
	attr_reader :name

	# Initializes Resource object
	#
	# @param [String] name the resource name
	# @param [String] type the type of HEAT resource
	# @param [String] properties the properties of HEAT resource
	def initialize(name, type, properties)
		@name = name
		@type = type
		@properties = properties
	end

	# Converts Resource object to HOT JSON format
	#
	# @return [JSON] the converted Resource object in HOT JSON format
	def to_json(*a)
		{type: @type, properties: @properties}.to_json(*a)
	end

	# Converts Resource object to HOT YAML format
	#
	# @return [YAML] the converted Resource object in HOT YAML format
	def to_yaml
		properties_not_empty = {}
		@properties.each { |key, value| properties_not_empty[key] = value unless value.nil? }
		{'type' => @type, 'properties' => properties_not_empty}
	end
end