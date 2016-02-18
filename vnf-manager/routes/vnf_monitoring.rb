# @see OrchestratorVnfManager
class OrchestratorVnfManager < Sinatra::Application

        # @method post_vnf-monitoring_vnfi_id_monitoring-parameters
        # @overload get '/vnf-monitoring/:vnfi_id/monitoring-parameters'
        #   Send monitoring info to VNF Monitoring
        #   @param [Integer] vnfi_id the VNF Instance ID
        # Send monitoring info to VNF Monitoring
        post '/vnf-monitoring/:vnfi_id/monitoring-parameters' do
                # Return if content-type is invalid
                halt 415 unless request.content_type == 'application/json'

                # Validate JSON format
                monitoring_info = parse_json(request.body.read)

                # Forward the request to the VNF Monitoring
                begin
                    response = RestClient.post "#{settings.vnf_monitoring}/vnf-monitoring/#{params[:vnfi_id]}/monitoring-parameters", monitoring_info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
                rescue Errno::ECONNREFUSED
                    halt 500, 'VNF Monitoring unreachable'
                rescue => e
                    logger.error e.response
                    halt e.response.code, e.response.body
                end

                halt response.code, response.body
        end

        post '/vnf-monitoring/:vnfi_id/readings' do
          # Return if content-type is invalid
          halt 415 unless request.content_type == 'application/json'

          # Validate JSON format
          monitoring_info = parse_json(request.body.read)

          # Forward the request to the VNF Monitoring
          begin
            #vnf-monitoring/:vnfi_id/readings
            response = RestClient.post "#{settings.vnf_monitoring}/vnf-monitoring/#{params[:vnfi_id]}/readings", monitoring_info.to_json, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
          rescue Errno::ECONNREFUSED
            halt 500, 'VNF Monitoring unreachable'
          rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
          end

          halt response.code, response.body
        end

        get '/vnf-monitoring/instances/:vnfi_id/monitoring-data/' do

          composedUrl = '/ns-monitoring/' + params["vnfi_id"].to_s + "/monitoring-data/?" + request.env['QUERY_STRING']
          # Forward the request to the VNF Monitoring
          begin
            #vnf-monitoring/:vnfi_id/readings
            response = RestClient.get "#{settings.vnf_monitoring}" + composedUrl, 'X-Auth-Token' => @client_token, :content_type => :json, :accept => :json
          rescue Errno::ECONNREFUSED
            halt 500, 'VNF Monitoring unreachable'
          rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
          end

          halt response.code, response.body
        end
        
end