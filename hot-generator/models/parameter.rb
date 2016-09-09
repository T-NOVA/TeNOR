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
class Parameter
  attr_reader :name

  # Initializes Parameter object
  #
  # @param [String] name the Output resource name
  # @param [String] description the Output description
  # @param [String] type the Parameter type
  def initialize(name, description, type)
    @name = name
    @description = description
    @type = type
  end

  # Converts Parameter object to HOT JSON format
  #
  # @return [JSON] the converted Parameter object in HOT JSON format
  def to_json(*a)
    {description: @description, type: @type}.to_json(*a)
  end

  # Converts Parameter object to HOT YAML format
  #
  # @return [YAML] the converted Parameter object in HOT YAML format
  def to_yaml
    {'description' => @description, 'type' => @type}
  end
end