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
# @see LoggerController
class LoggerController < TnovaManager

	# @method get_elastic
	# @overload get '/elastic/*'
	# Get logs from elasticsearch/logstash. Different strings allowed in order to filter the required data
	# @param [string]
  get '/*' do
  	begin
  		response = RestClient::Request.new(
		    :method => :get,
		    :url => settings.elasticsearch + request.fullpath.split("elastic")[1].to_s,
				:user => settings.logstash_user,
		    :password => settings.logstash_password,
		    :headers => { :accept => :json,
		    :content_type => :json }
		  ).execute
		rescue Errno::ECONNREFUSED
			halt 500, 'ElasticSerch/Logstash unreachable'
		rescue => e
			puts e
			halt 400, 'Error'
			#halt e.response.code, e.response.body
		end

    return response
  end

end