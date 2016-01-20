require 'sinatra/base'

module Sinatra
  module Gk_Auth
    module Helpers

      def authorized?

        if request.env['HTTP_X_AUTH_TOKEN'].to_s.empty?
          halt 401, {'Content-Type' => 'text/plain'}, 'Token invalid.'
        end

        if settings.gk.empty?
          halt 401, {'Content-Type' => 'text/plain'}, 'No gatekeeper url defined.'
        end

        if settings.service_key.empty?
          halt 401, {'Content-Type' => 'text/plain'}, 'No service key defined.'
        end

        begin
          RestClient.get settings.gk + '/token/validate/' + request.env['HTTP_X_AUTH_TOKEN'].to_s, :content_type => :json, :"X-Auth-Service-Key" => settings.service_key
        rescue => e
          halt 400, {'Content-Type' => 'text/plain'}, e.response
        end
      end

      def parse_json(message)
        begin
          parsed_message = JSON.parse(message) # parse json message
        rescue JSON::ParserError => e
          return message, e.to_s + "\n"
        end
        return parsed_message, nil
      end

      def updateValues(key, value)
        if key == 'gk'
          settings.gk = value
        elsif key == 'service_key'
          settings.service_key = value
        end
      end

    end

    def self.registered(app)

      app.helpers Gk_Auth::Helpers

      app.post '/gk_credentials' do

        #credentials = {gk_url: url, service_key: key}
        return 415 unless request.content_type == 'application/json'
        credentials, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        app.set :gk, credentials['gk_url']
        app.set :service_key, credentials['service_key']

        updateValues("gk", credentials['gk_url'])
        updateValues("service_key", credentials['service_key'])

        return 200
      end

    end
  end

  register Gk_Auth
end
