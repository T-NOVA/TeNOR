#
# TeNOR - NS Provisioning
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
# @see Provisioner
module UtilsHelper

  # Checks if a JSON message is valid
  #
  # @param [JSON] message some JSON message
  # @return [Hash, nil] if the parsed message is a valid JSON
  # @return [Hash, String] if the parsed message is an invalid JSON
  def parse_json(message)
    # Check JSON message format
    begin
      parsed_message = JSON.parse(message) # parse json message
    rescue JSON::ParserError => e
      # If JSON not valid, return with errors
      logger.error "JSON parsing: #{e.to_s}"
      return message, e.to_s + "\n"
    end

    return parsed_message, nil
  end

  def update_mongoid_array(object, old_array, new_array)
    #get array
    object = @resource_reservation.find {|s| s[:network_stack][:id] == stack['stack']['id'] }
    #remove array
          #@instance.resource_reservation.delete(object)
          #@instance.pop(resource_reservation: resource_reservation)
          @instance.pull(resource_reservation: object)
    #add array
    resource_reservation = resource_reservation.find {|s| s[:network_stack][:id] == stack['stack']['id'] }
    resource_reservation[:routers] = routers
    @instance.push(resource_reservation: resource_reservation)
    return object
  end
end
