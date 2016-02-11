#
# TeNOR - NS Instance Repository
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
# @see OrchestratorNsInstanceRepository
class OrchestratorNsInstanceRepository < Sinatra::Application

	before do

		if request.path_info == '/gk_credentials'
			return
		end

		if settings.environment == 'development'
			return
		end

		authorized?
	end

  # @method get_ns-instances
  # @overload get "/ns-instances"
  # Gets all ns-instances
	get '/ns-instances' do
    if params[:status]
      @nsInstances = Nsr.where(:status => params[:status])
    else
      @nsInstances = Nsr.all
    end

		return @nsInstances.to_json
	end

  # @method get_ns-instance
  # @overload get "/ns-instances/:id"
  # Get a ns-instance
	get '/ns-instances/:id' do
		begin
			@nsInstance = Nsr.find(params["id"])
		rescue Mongoid::Errors::DocumentNotFound => e
			halt(404)
		end
		return @nsInstance.to_json
  end

  # @method post_ns-instances
  # @overload post "/ns-instances"
  # Post a new ns-instances information
	post '/ns-instances' do
		return 415 unless request.content_type == 'application/json'

		instance, errors = parse_json(request.body.read)
		return 400, errors.to_json if errors
		
		instance = Nsr.new(instance)
		instance.save!

		return 200, instance.to_json
	end

  # @method get_ns-instances
  # @overload get "/ns-instances"
  # Update a ns-instance
	put '/ns-instances/:id' do
		return 415 unless request.content_type == 'application/json'

		nsInstance, errors = parse_json(request.body.read)
		return 400, errors.to_json if errors

		begin
			@instance = Nsr.find(params["id"])
		rescue Mongoid::Errors::DocumentNotFound => e
			logger.error e
			return 404
		end

		@instance.update_attributes(nsInstance)

		return 200, @instance.to_json
	end

  # @method delete_ns-instances
  # @overload delete "/ns-instances/:id"
  # Delete a ns-instance
	delete '/ns-instances/:id' do
		begin
			@nsInstance = Nsr.find(params["id"])
		rescue Mongoid::Errors::DocumentNotFound => e
			halt(404)
		end
		@nsInstance.delete
	end

end