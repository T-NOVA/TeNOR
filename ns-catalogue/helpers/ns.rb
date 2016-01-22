#
# TeNOR - NS Catalogue
#
# Copyright 2014-2016 i2CAT Foundation
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
# @see OrchestratorNsCatalogue
class OrchestratorNsCatalogue < Sinatra::Application

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

	def build_http_link(offset, limit)
		link = ''
		# Next link
		next_offset = offset + 1
		next_nss = Ns.paginate(:page => next_offset, :limit => limit)
		begin
			link << '<localhost:4011/network-services?offset=' + next_offset.to_s + '&limit=' + limit.to_s + '>; rel="next"' unless next_nss.empty?
		rescue
			logger.error "Error Establishing a Database Connection"
		end

		unless offset == 1
			# Previous link
			previous_offset = offset - 1
			previous_nss = Ns.paginate(:page => previous_offset, :limit => limit)
			unless previous_nss.empty?
				link << ', ' unless next_nss.empty?
				link << '<localhost:4011/network-services?offset=' + previous_offset.to_s + '&limit=' + limit.to_s + '>; rel="last"'
			end
		end
		link
	end
	
end