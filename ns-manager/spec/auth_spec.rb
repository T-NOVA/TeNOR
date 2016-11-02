require_relative 'spec_helper'

RSpec.describe TnovaManager do
	def app
		TeNORAuthentication
  end

	before do
		begin
			DatabaseCleaner.start
		ensure
			DatabaseCleaner.clean
		end
	end

	describe 'POST /auth' do
		let(:user) { create :user }
		context 'given an invalid content type' do
			let(:response) { post '/login', {username: 'teste', password: 'secret'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given an invalid login credentials' do
			let(:response) { post '/login', {username: 'test', password: 'secret'}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 401' do
				expect(response.status).to eq 401
      end

			it 'responds with an empty body' do
				expect(response.body).to be_a String
			end
		end

		context 'given an invalid login credentials' do
			let(:response) { post '/login', {username: user.name, password: 'invalid_secret'}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 401' do
				expect(response.status).to eq 401
      end

			it 'responds with an empty body' do
				expect(response.body).to be_a String
			end
		end

		context 'given a valid login credentials' do
			let(:response) { post '/login', {username: user.name, password: 'secret'}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'response body should contain a Hash with the token' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	#token auth
	describe 'POST /auth' do
		let(:token) { create :user_token }

		context 'given an invalid content type' do
			let(:response) { post '/validation', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given an invalid token' do
			let(:response) { post '/validation', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }
			it 'responds with a 404' do
				expect(response.status).to eq 404
      end
		end

		context 'given a valid token' do
			let(:response) { post '/validation', {token: token.token}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }
			it 'responds with a 200' do
				puts token.token
				expect(response.status).to eq 200
      end
		end

		context 'given a missing header credentials' do
			let(:response) { post '/logout', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
      end

			it 'responds with a string body' do
				expect(response.body).to be_a String
			end
		end

		context 'given an invalid token credentials' do
			let(:response) { post '/logout', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json', 'HTTP_X_AUTH_TOKEN' => "invalid token"} }

			it 'responds with a 401' do
				expect(response.status).to eq 401
      end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid token credentials' do
			let(:response) { post '/logout', {}.to_json, rack_env={'CONTENT_TYPE' => 'application/json', 'HTTP_X_AUTH_TOKEN' => token.token} }

			it 'responds with a 200' do
				expect(response.status).to eq 200
      end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end
	end

	#update user password
	describe 'PUT /auth' do
		let(:user) { create :user }

		context 'given a missing header credentials' do
			let(:response) { put '/invalid_id/update_password', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				puts user.id
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given an invalid user id' do
			let(:response) { put '/invalid_id/update_password', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 404' do
				expect(response.status).to eq 401
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid user id but invalid passwords' do
			let(:response) { put '/' + user.id.to_s + '/update_password', {old_password: "secret2", password: "secret2", re_password: "secret2"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 404' do
				puts user.id
				expect(response.status).to eq 404
      end

			it 'response body should contain a String' do
				puts user.id
				expect(response.body).to be_a String
			end
		end

		context 'given a valid user id but invalid passwords' do
			let(:response) { put '/' + user.id.to_s + '/update_password', {old_password: "secret", password: "secret2", re_password: "secret3"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 404' do
				puts user.id
				expect(response.status).to eq 404
      end

			it 'response body should contain a String' do
				expect(response.body).to be_a String
			end
		end

		context 'given a valid user id and valid passwords' do
			let(:response) { put '/' + user.id.to_s + '/update_password', {old_password: "secret", password: "secret2", re_password: "secret2"}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 200' do

					puts user.name
					puts user.password
				expect(response.status).to eq 200
      end

			it 'response body should be empty' do
				expect(response.body).to be_empty
			end
		end
	end

=begin
	describe 'POST /auth' do
		context 'given an invalid content type' do
			let(:response) { post '/register', {name: 'teste'}.to_json, rack_env={'CONTENT_TYPE' => 'application/x-www-form-urlencoded'} }

			it 'responds with a 415' do
				expect(response.status).to eq 415
			end

			it 'responds with an empty body' do
				expect(response.body).to be_empty
			end
		end

		context 'given a valid DC' do
			let(:response) { post '/user', {name: "name", host: "host", user: "user", password: "", tenant_name: "tenan", extra_info: "extra..."}.to_json, rack_env={'CONTENT_TYPE' => 'application/json'} }

			it 'responds with a 201' do
				expect(response.status).to eq 201
      end

			it 'response body should contain a Hash (DC)' do
				expect(JSON.parse response.body).to be_a Hash
			end
		end
	end

	describe 'GET /auth' do
		context 'when there are no DCs' do
			let(:response) { get '/dc' }

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'returned array should be empty' do
				expect(JSON.parse response.body).to be_empty
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
    end

		context 'when there are one or more DCs' do
			before { create_pair(:dc) }
			let(:response) { get '/dc' }

			it 'does not return an empty body' do
				expect(JSON.parse response.body).to_not be_empty
			end

			it 'returns an array' do
				expect(JSON.parse response.body).to be_an Array
			end

			it 'each array item should be a Hash (NS)' do
				expect(JSON.parse response.body).to all be_a Hash
			end

			it 'responds with a 200' do
				expect(response.status).to eq 200
			end
		end
	end
=end
end
