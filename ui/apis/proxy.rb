require 'sinatra/base'
require 'json'
require 'rest-client'

class App::Proxy < Sinatra::Base

  get '/rest/api/*' do

    host = request.env["HTTP_X_HOST"]

    begin
      response = RestClient.get host + "/" + params[:splat][0] + "?" + request.env['QUERY_STRING'], :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR - " + e.to_s
      halt 400
    end
    return response

  end

  post '/rest/api/*' do

    host = request.env["HTTP_X_HOST"]
    body = request.body.read

    begin
      response = RestClient.post host + "/" + params[:splat][0], body, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e
      halt 400
    end
    return response
  end

  put '/rest/api/*' do

    host = request.env["HTTP_X_HOST"]
    body = request.body.read

    begin
      response = RestClient.put host + "/" + params[:splat][0], body, :content_type => :json
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e
      halt 400
    end
    return response
  end

  delete '/rest/api/*' do

    host = request.env["HTTP_X_HOST"]

    begin
      response = RestClient.delete host + "/" + params[:splat][0], :content_type => :json
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
