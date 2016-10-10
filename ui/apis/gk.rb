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
    rescue RestClient::Unauthorized => e¡
      puts e
      halt 401, "Unauthorized"
    rescue => e
      puts "ERROR"
      puts e
      halt 400
    end
    puts "Response..."
    return response

  end

  post '/rest/gk/api/token/' do

    host = request.env["HTTP_X_HOST"]
    username = request.env["HTTP_X_AUTH_UID"]
    passwd = request.env["HTTP_X_AUTH_PASSWORD"]

    #given user name, look database
    admin_user = {:uid => App.admin_user_uid, :passwd => App.admin_user_passwd}
    admin_token = loginToGk(host, admin_user)
    users_list, users_ids = getListUsers(host, admin_token)
    index_position = users_list.find_index { |name| name == username }
    if index_position.nil?
      puts "User not found."
      halt 400, "User not found"
    end
    uid = users_ids[index_position]

    begin
      response = RestClient.post host + "/token/", "", :content_type => :json, :'X-Auth-Uid' => uid, :'X-Auth-Password' => passwd
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e
      halt 400, "Login failed."
    end
    response = JSON.parse(response)
    response['uid'] = uid
    return response.to_json
  end

  post '/rest/gk/api/*' do

    host = request.env["HTTP_X_HOST"]
    token = request.env["HTTP_X_AUTH_TOKEN"]
    body = request.body.read

    begin
      response = RestClient.post host + "/" + params[:splat][0], body, :content_type => :json, :'X-Auth-Token' => token
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e
      halt e.response.code, e.response.body
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

  def loginToGk(host, user)
    puts host + "/token/"
    puts user[:uid]
    puts user[:passwd]
    begin
      response = RestClient.post host + "/token/", "", :content_type => :json, :'X-Auth-Uid' => user[:uid], :'X-Auth-Password' => user[:passwd]
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e.response
      halt 400
    end
    response = JSON.parse(response)
    return response['token']['id']
  end

  def getListUsers(host, token)
    begin
      response = RestClient.get host + "/admin/user/", :content_type => :json, :'X-Auth-Token' => token
    rescue Errno::ECONNREFUSED
      halt 500, "Errno::ECONNREFUSED"
    rescue => e
      puts "ERROR"
      puts e
      halt 400
    end
    response = JSON.parse(response)
    return response['userlist'], response['userids']
  end

end
