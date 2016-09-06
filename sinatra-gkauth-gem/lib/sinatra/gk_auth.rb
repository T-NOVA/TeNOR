require 'sinatra/base'
require 'json'

module Sinatra
  module Gk_Auth
    module Helpers

      def initialize
        puts "Initializing gem GK..."

        service_info = {:name => settings.servicename, :host => "localhost", :port => settings.port, :path => "" }
        begin
          RestClient.post settings.manager + '/configs/services/publish/' + settings.servicename, service_info.to_json, :accept => :json, :content_type => :json
        rescue => e
          puts "Error registring or receiving dependencies from NS Manager"
          puts e
        end

        return
      end

      def authorized?

        if request.env['HTTP_X_AUTH_TOKEN'].to_s.empty?
          halt 401, {'Content-Type' => 'text/plain'}, 'Token invalid.'
        end

        if settings.gk.nil?
          halt 401, {'Content-Type' => 'text/plain'}, 'No gatekeeper url defined.'
        end

        if settings.service_key.nil?
          halt 401, {'Content-Type' => 'text/plain'}, 'No service key defined.'
        end

        begin
          RestClient.get settings.gk + '/token/validate/' + request.env['HTTP_X_AUTH_TOKEN'].to_s, :content_type => :json, :"X-Auth-Service-Key" => settings.service_key
        rescue => e
          halt 400, {'Content-Type' => 'text/plain'}, e.response
        end
      end

      # Checks if a JSON message is valid
      #
      # @param [JSON] message some JSON message
      # @return [Hash, nil] if the parsed message is a valid JSON
      # @return [Hash, String] if the parsed message is an invalid JSON
      def parse_json(message)
        begin
          parsed_message = ::JSON.parse(message) # parse json message
        rescue => e
          puts "Error"
          puts e
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

      def updateConfigValues(key, value)
          settings[key] = value
      end

    end

    def self.registered(app)

      app.helpers Gk_Auth::Helpers

      app.before do
        #env['rack.logger'] = app.settings.logger
        if request.path_info == '/gk_credentials'
          return
        end

        if settings.environment == 'development'
          return
        end
        authorized?
      end

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

      app.post '/gk_dependencies' do

        return 415 unless request.content_type == 'application/json'

        services, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        puts "Services publishing..."
        if settings.dependencies.nil?
          return 200
        end
        services.each do |service|
          if !settings.dependencies.detect{ |sv| sv == service['name'] }.nil?
            app.set service['name'], service['host'] + ":" + service['port']# unless service['name'] == 'logstash'
          end
        end

        return 200
      end

    end
  end

  register Gk_Auth
end
