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
class Output
	attr_reader :name

	# Initializes Output object
	#
	# @param [String] name the Output resource name
	# @param [String] description the Output description
	# @param [String] value the Output value
	def initialize(name, description, value)
		@name = name
		@description = description
		@value = value
	end

	# Converts Output object to HOT JSON format
	#
	# @return [JSON] the converted Output object in HOT JSON format
	def to_json(*a)
		{description: @description, value: @value}.to_json(*a)
	end

	# Converts Output object to HOT YAML format
	#
	# @return [YAML] the converted Output object in HOT YAML format
	def to_yaml
		{'description' => @description, 'value' => @value}
	end
end