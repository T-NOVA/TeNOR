#
# TeNOR - NS Manager
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
# @see ApplicationHelper
module MappingHelper

  # Get list of Mapping Algorithms
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
  def getMappings()
    begin
        return 200, Mapping.all.to_json
    rescue => e
        logger.error e
        logger.error 'Error Establishing a Database Connection'
        return 500, 'Error Establishing a Database Connection'
    end
  end

  # Get a Mapping
  #
  # @param [Symbol] format the format type, `:text` or `:html`
  # @return [String] the object converted into the expected format.
  def getMapping(id)
    begin
        dc = Mapping.find(id)
    rescue Mongoid::Errors::DocumentNotFound => e
        logger.error 'mapping not found'
        return 404
    end
    return dc.to_json
  end

  def saveMapping(mapping)
    begin
            mapping = Mapping.find_by(name: mapping['name'])
            halt 409, 'DC Duplicated. Use PUT for update.'
        # i es.update_attributes!(:host => pop_info['host'], :port => pop_info['port'], :token => @token, :depends_on => serv_reg['depends_on'])
        rescue Mongoid::Errors::DocumentNotFound => e
            begin
                mapping = Mapping.create!(mapping)
            rescue => e
                logger.error 'ERROR.................'
                logger.error e
            end
        rescue => e
            logger.error e
            logger.error 'Error saving mapping.'
            halt 400
        end
  end

end
