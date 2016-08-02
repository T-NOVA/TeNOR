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
# @see TnovaManager
module AuthenticationHelper

	# Register service in Gatekeeper
	#
  # @param [String] serviceName
	# @return [String] the register information
	def registerServiceinGK(serviceName)
		service = {"shortname" => serviceName, "description" => ""}

		if Sinatra::Application.settings.gk_token === nil
			return
		end
		begin
			key = RestClient.post Sinatra::Application.settings.gatekeeper + '/admin/service/', service.to_json, :content_type => :json, :"X-Auth-Token" => settings.gk_token
		rescue => e
			if e.response == nil
				halt 500, {'Content-Type' => 'text/plain'}, "Register service error."
			end
			halt 400, {'Content-Type' => 'text/plain'}, e.response
		end
		return key
	end

	# Register user to gatekepeer.
	#
	# @param [String] username
	# @return [String] the object converted into the expected format.
	def registerUserinGK(userName, accessList)
		user = {
			"username" => userName,
			"password" => "somepass",
			"isadmin" => "n",
			"accesslist" => accessList
		}
		begin
			user = RestClient.post Sinatra::Application.settings.gatekeeper + '/admin/user/', user.to_json, :content_type => :json, :accept => :json
		rescue => e
			if e.response == nil
				halt 500, {'Content-Type' => 'text/plain'}, "Register user error."
			end
			halt 400, {'Content-Type' => 'text/plain'}, e.response
		end
		return user
	end

	# Sends the Gatekeeper key to the specific microservice
	#
	# @param [String] Microservice url
	# @param [String] Microservice key
	def self.sendServiceAuth(microservice, key)
		credentials = {gk_url: Sinatra::Application.settings.gatekeeper, service_key: key}
		begin
			RestClient.post microservice + '/gk_credentials', credentials.to_json, :content_type => :json
		rescue => e
			puts e
			#halt 400, {'Content-Type' => 'text/plain'}, e
		end
	end

	# Send service key to a mS
	#
	# @return [String] the object converted into the expected format.
	def self.loginGK()
		begin
			response = RestClient.post Sinatra::Application.settings.gatekeeper + '/token/', "", :"X-Auth-Password" => Sinatra::Application.settings.gk_pass, :"X-Auth-Uid" => Sinatra::Application.settings.gk_user_id
		rescue => e
			puts e
			#logger.error "Error with the login to Gatekeeper"
			return
		end
		if response.nil?
			#halt 500, "Gatekeeper response is null when login."
		end
		metadata = JSON.parse(response)
    Sinatra::Application.settings.gk_token =  metadata["token"]["id"]
	end

	# Get registered services in Gatekeeper
	#
	# @return [Array] list of services.
	def self.getGKServices()
		begin
			response = RestClient.get Sinatra::Application.settings.gatekeeper + '/admin/service/', :content_type => :json, :"X-Auth-Token" => Sinatra::Application.settings.gk_token
    rescue => e
      puts "Error"
      puts e
			#logger.error e
    end
    puts response
		metadata = JSON.parse(response)
		return metadata['servicelist']
	end

end