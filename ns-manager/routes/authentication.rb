#
# TeNOR - NS Manager
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
# @see Authentication
class TeNORAuthentication < TnovaManager
    post '/validation' do
        return 415 unless request.content_type == 'application/json'
        token, errors = parse_json(request.body.read)
        logger.error errors if errors
        halt 400 if errors

        begin
            token = UserToken.find_by(token: token['token'])
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'User not found.'
            halt 404
        end
        logger.info 'Token validated.'
        halt 200
    end

    post '/login' do
        return 415 unless request.content_type == 'application/json'
        credentials, errors = parse_json(request.body.read)
        logger.error errors if errors
        halt 400 if errors

        halt 401, 'Username not defined.' if credentials['username'].nil?
        begin
            user = User.find_by(name: credentials['username'].downcase)
        rescue Mongoid::Errors::DocumentNotFound => e
            logger.error 'User not found.'
            halt 401
        end
        if !user.active
            halt 401, 'User is not actived'
        else
            if user.password_hash == BCrypt::Engine.hash_secret(credentials['password'], user.password_salt)
                token = BCrypt::Engine.generate_salt
                tkn = { uid: user.id, token: token, expires_at: Time.now.to_i + (60 * 60), expires: false }
                user.user_tokens << UserToken.create!(tkn)
                # user.last_sign_in_ip = ip
                user.last_sign_in_at = Time.now
                user.sign_in_count = 0
                user.save!
                halt 200, tkn.to_json
            else
                # user.last_failed_login_timestamp = Time.now
                # user.failed_logins = user.failed_logins.to_i + 1
                # user.last_failed_login_ip = ip
                user.save!
                halt 401, { 'Content-Type' => 'text/plain' }, 'User/Password combination does not match'
            end
        end
        halt 400
    end

    post '/logout' do
        return 415 if request.env['HTTP_X_AUTH_TOKEN'].nil?
        begin
            token = UserToken.find_by('token' => request.env['HTTP_X_AUTH_TOKEN'])
        rescue Mongoid::Errors::DocumentNotFound => e
            halt 401
        end
        token.destroy
        halt 200
    end

    post '/register' do
        user = User.new
        # user.name = params[:user][:name]
        user.name = params[:username].downcase
        user.password = params[:password]
        user.password_salt = BCrypt::Engine.generate_salt
        user.password_hash = BCrypt::Engine.hash_secret(params[:password], user.password_salt)
        user.email = params[:email]
        user.fullname = params[:fullname]
        user.active = 0
        # user.roles << Role.where(name: "tenantuser").first
        begin
            user.save!
            status 201
        rescue => ex
            puts "Error #{$ERROR_INFO}"
            halt 422, { 'Content-Type' => 'text/plain' }, ex.message
        end
    end

    delete '/:uid' do
        puts 'Delete user'
        puts 'Admin user cannot be deleted.'
    end

    post '/:uid/reset_password' do
        user = User.where(email: params[:email]).first
        user.password_reset_hash = BCrypt::Engine.generate_salt
        recoverPassMail(user.email, password_reset_hash)
    end

    put '/:uid/update_password' do
        user = User.where(email: params[:email], password_reset_hash: params[:verification_code]).first
        user.password = params[:password]
        user.password_salt = BCrypt::Engine.generate_salt
        user.password_hash = BCrypt::Engine.hash_secret(params[:password], user.password_salt)
        if user.password == password_confirmation
            user.password_reset_hash = ''
            user.save!
        end
        status 200
    end
end
