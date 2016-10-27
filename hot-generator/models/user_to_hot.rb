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
class UserToHot

  # Initializes UserToHot object
  #
  # @param [String] name the name for the HOT
  # @param [String] description the description for the HOT
  def initialize(name, description)
    @hot = Hot.new(description)
    @name = name
  end

  # Create a User HOT
  #
  # @param [Hash] credentials_info information about the User
  # @return [HOT] returns an HOT object
  def build(credentials_info)

    username = credentials_info['username']
    project_name = credentials_info['project_name']
    password = credentials_info['password']

    project = create_project(project_name, nil)
    create_user(username, project, password)

    #puts @hot.to_yaml

    @hot
  end

  # Creates a HEAT project resource
  #
  # @param [String] project_name the name of the project
  # @return [String] domain the name of the domain
  def create_project(project_name, domain)
    name = get_resource_name
    @hot.resources_list << Project.new(name, project_name, domain)
    @hot.outputs_list << Output.new("project_id", "The project id", {"get_resource" => name})
    name
  end

  # Creates a HEAT user resource
  #
  # @param [String] username the username
  # @return [String] project the name of the created resource
  # @return [String] password the password to be used
  def create_user(username, project, password)
    name = get_resource_name
    @hot.resources_list << User.new(name, username, {"get_resource" => project}, password)
    @hot.outputs_list << Output.new("user_id", "The user id", {"get_resource" => name})
    name
  end

  # Generates a new resource name
  #
  # @return [String] the generated resource name
  def get_resource_name
    @name + '_' + @hot.resources_list.length.to_s unless @name.empty?
  end

end
