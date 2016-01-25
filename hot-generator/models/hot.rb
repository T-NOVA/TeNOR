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
class Hot
	attr_accessor :resources_list, :outputs_list

	# Initializes Hot object
	#
	# @param [String] description the description of Hot object
	def initialize(description)
		@version = '2014-10-16'
		@description = description
		@resources_list = []
		@outputs_list = []
	end

	# Converts Hot object to HOT JSON format
	#
	# @return [JSON] the converted Hot object in HOT JSON format
	def to_json(*a)
		# Resources
		resources = {}
		@resources_list.each do |resource|
			resources[resource.name] = resource
		end

		# Outputs
		outputs = {}
		@outputs_list.each do |output|
			outputs[output.name] = output
		end

		{heat_template_version: @version, description: @description, resources: resources, outputs: outputs}.to_json(*a)
	end

	# Converts Hot object to HOT YAML format
	#
	# @return [YAML] the converted Hot object in HOT YAML format
	def to_yaml
		# Resources
		resources = {}
		@resources_list.each do |resource|
			resources[resource.name] = resource.to_yaml
		end

		# Outputs
		outputs = {}
		@outputs_list.each do |output|
			outputs[output.name] = output
		end

		{'heat_template_version' => @version, 'description' => @description, 'resources' => resources, 'outputs' => outputs}.to_yaml
	end
end