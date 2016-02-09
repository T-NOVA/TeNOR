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
        
end