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
class TnovaManager < Sinatra::Application

	def registerServiceinGK(serviceName)
		service = {"shortname" => serviceName, "description" => ""}

		if settings.gk_token === nil
			return
		end
		begin
			key = RestClient.post settings.gatekeeper + '/admin/service/', service.to_json, :content_type => :json, :"X-Auth-Token" => settings.gk_token
		rescue => e
			if e.response == nil
				halt 500, {'Content-Type' => 'text/plain'}, "Register service error."
			end
			halt 400, {'Content-Type' => 'text/plain'}, e.response
		end
		return key
	end

	def registerUserinGK(userName, accessList)
		user = {
			"username" => userName,
			"password" => "somepass",
			"isadmin" => "n",
			"accesslist" => accessList
		}
		begin
			user = RestClient.post settings.gatekeeper + '/admin/user/', user.to_json, :content_type => :json, :accept => :json
		rescue => e
			if e.response == nil
				halt 500, {'Content-Type' => 'text/plain'}, "Register user error."
			end
			halt 400, {'Content-Type' => 'text/plain'}, e.response
		end
		return user
	end
	
	#send service key to a mS
	def sendServiceAuth(microservice, key)
		credentials = {gk_url: settings.gatekeeper, service_key: key}
		begin
			RestClient.post microservice + '/gk_credentials', credentials.to_json, :content_type => :json
		rescue => e
			logger.error e
			if e.response == nil
				halt 500, {'Content-Type' => 'text/plain'}, "MS unreachable."
			end
			halt 400, {'Content-Type' => 'text/plain'}, e.response
		end
	end

	#send service key to a mS
	def loginGK()
		begin
			response = RestClient.post settings.gatekeeper + '/token/', "", :"X-Auth-Password" => settings.gk_pass, :"X-Auth-Uid" => settings.gk_user_id
		rescue => e
			logger.error e
		end
		if response.nil?
			halt 500, "Gatekeeper response is null when login."
		end
		metadata = JSON.parse(response)
		settings.gk_token =  metadata["token"]["id"]
	end

	#send service key to a mS
	def getGKServices()
		begin
			response = RestClient.get settings.gatekeeper + '/admin/service/', :content_type => :json, :"X-Auth-Token" => settings.gk_token
		rescue => e
			logger.error e
		end
		metadata = JSON.parse(response)
		return metadata['servicelist']
	end

end