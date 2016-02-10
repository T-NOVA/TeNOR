# Copyright 2014-2016 Universita' degli studi di Milano
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# -----------------------------------------------------
#
# Authors:
#     Alessandro Petrini (alessandro.petrini@unimi.it)
#
# -----------------------------------------------------



# @see sm-unimi
class MapperUnimi < Sinatra::Application


# --- CORS management
	before do
		content_type :json
		headers 'Access-Control-Allow-Origin' => '*',
				'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
	end
	#set :protection, false
# --- route OPTIONS for browser callings (again, CORS related...)
	options "*" do
		response.headers["Allow"] = "HEAD,GET,POST,DELETE,OPTIONS"
		response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
		response.headers["Access-Control-Allow-Origin"] = "*"
		200
	end


	post '/mapper' do
		return mapper_manager()
	end

end
