require 'sinatra/base'
require 'json'
require 'rest-client'
require 'jwt'

module Sinatra
    module Gk_Auth
        module Helpers
            $time = 5
            $max_retries = 150 # in seconds
            def initialize
                sleep(2)
                puts 'Initializing Sinatra Auth gem ...'
                begin
                    service_info = { name: settings.servicename, host: settings.address, port: settings.port, depends_on: settings.dependencies, secret: settings.servicename, type: settings.type}
                rescue
                    service_info = { name: settings.servicename, host: settings.address, port: settings.port, depends_on: settings.dependencies, secret: settings.servicename, type: "" }
                end
                publish_service(service_info) if settings.environment != 'development'

                if settings.environment == 'development'
                    puts 'Running the module in development mode.'
                    Thread.new do
                        response = publish_service(service_info)
                    end
                end
                nil
            end

            def publish_service(service_info)
                begin
                    response = RestClient.post settings.manager + '/modules/services', service_info.to_json, accept: :json, content_type: :json
                rescue => e
                    puts 'Error registring or receiving dependencies to the Manager, waiting: ' + $time.to_s + ' seconds for next retry...'
                    puts e
                    sleep($time) # wait $time seconds
                    $time = $time * 2
                    $time = 5 if $time > $max_retries
                    publish_service(service_info)
                end
                return if response.nil?
                services, errors = parse_json(response)
                return 400, errors.to_json if errors

                services['depends_on'].each do |service|
                    name = service['name'].to_s
                    host = service['host'] + ':' + service['port'].to_s
                    Sinatra::Application.set service['name'], host # unless service['name'] == 'logstash'
                    Sinatra::Application.set service['name'] + '_token', service['token'] # unless service['name'] == 'logstash'
                    eval('settings.'+name+'="'+host+'"')
                    eval('settings.'+name+'_token="'+service['token']+'"')
                end
                response
            end

            def authorized?
                if settings.environment != 'development'
                    if request.env['HTTP_X_AUTH_TOKEN'].to_s.empty?
                        halt 401, { 'Content-Type' => 'text/plain' }, 'Token invalid.'
                    end

                    begin
                        JWT.decode request.env['HTTP_X_AUTH_TOKEN'], settings.servicename, true, algorithm: 'HS256'
                    rescue JWT::VerificationError
                        halt 401, { 'Content-Type' => 'text/plain' }, 'Invalid token'
                    rescue JWT::InvalidJtiError
                        # Handle invalid token, e.g. logout user or deny access
                        puts 'Error'
                        halt 400, { 'Content-Type' => 'text/plain' }, 'Invalid token'
                    end
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
                    puts 'Error'
                    puts e
                rescue JSON::ParserError => e
                    return message, e.to_s + "\n"
                end
                [parsed_message, nil]
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

            app.before do
                return if settings.environment == 'development' || request.path_info == "/services"
                authorized?
            end

            app.get '/services' do
                arr = []
                settings.dependencies.each do |s, k|
                    arr << { name: s, host: eval("settings."+s.to_s) }
                end
                arr.to_json
            end

            app.post '/gk_dependencies' do
                return 415 unless request.content_type == 'application/json'

                ms, errors = parse_json(request.body.read)
                return 400, errors.to_json if errors

                return 200 if settings.dependencies.nil?
                unless settings.dependencies.detect { |sv| sv == ms['name'] }.nil?
                    app.set ms['name'], ms['host'].to_s + ':' + ms['port'].to_s
                    app.set ms['name'] + '_token', ms['token'].to_s
                end

                return 200
            end
        end
    end

    register Gk_Auth
end
