require 'sinatra/base'
require 'json'
require 'rest-client'

class App::Gk < Sinatra::Base

	get '/rest/gk/api/*' do
		
		host = request.env["HTTP_X_HOST"]
        token = request.env["HTTP_X_AUTH_TOKEN"]
        
       begin
           response = RestClient.get host + "/" + params[:splat][0], :content_type => :json, :'X-Auth-Token' => token
		rescue Errno::ECONNREFUSED
            halt 500, "Errno::ECONNREFUSED"
        rescue => e
            puts "ERROR"
            puts e
            halt 400
		end
        return response

	end

	post '/rest/gk/api/*' do

		host = request.env["HTTP_X_HOST"]
		uid = request.env["HTTP_X_AUTH_UID"]
		passwd = request.env["HTTP_X_AUTH_PASSWORD"]
        
       begin
            response = RestClient.post host + "/" + params[:splat][0], "", :content_type => :json, :'X-Auth-Uid' => uid, :'X-Auth-Password' => passwd
		rescue Errno::ECONNREFUSED
            halt 500, "Errno::ECONNREFUSED"
        rescue => e
            puts "ERROR"
            puts e
            halt 400
		end
        return response
    end
    
    put '/rest/gk/api/*' do
		
		host = request.env["HTTP_X_HOST"]
        token = request.env["HTTP_X_AUTH_TOKEN"]
        body = request.body.read
        
       begin
           response = RestClient.put host + "/" + params[:splat][0], body, :content_type => :json, :'X-Auth-Token' => token
		rescue Errno::ECONNREFUSED
            halt 500, "Errno::ECONNREFUSED"
        rescue => e
            puts "ERROR"
            puts e
            halt 400
		end
        return response

	end
    
    delete '/rest/gk/api/*' do
		
		host = request.env["HTTP_X_HOST"]
        token = request.env["HTTP_X_AUTH_TOKEN"]
        
       begin
           response = RestClient.delete host + "/" + params[:splat][0], :content_type => :json, :'X-Auth-Token' => token
		rescue Errno::ECONNREFUSED
            halt 500, "Errno::ECONNREFUSED"
        rescue => e
            puts "ERROR"
            puts e
            halt 400
		end
        return response

	end

end
