#
# TeNOR - NS Monitoring
#
# Copyright 2014-2016 i2CAT Foundation, Portugal Telecom Inovação
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
# @see NSMonitoring
module MonitoringHelper
    @conn = Bunny.new
    @conn.start
    @channel = @conn.create_channel
    @@testThreads = []

    # Checks if a JSON message is valid
    #
    # @param [JSON] message some JSON message
    # @return [Hash, nil] if the parsed message is a valid JSON
    # @return [Hash, String] if the parsed message is an invalid JSON
    def parse_json(message)
        # Check JSON message format
        begin
            parsed_message = JSON.parse(message) # parse json message
        rescue JSON::ParserError => e
            # If JSON not valid, return with errors
            logger.error "JSON parsing: #{e}"
            return message, e.to_s + "\n"
        end

        [parsed_message, nil]
    end

    # Subcription thread method
    #
    # @param [JSON] message monitoring information
    def self.subcriptionThread(monitoring)
        logger.info 'Subcription thread for NSr: ' + monitoring['nsi_id'].to_s
        nsi_id = monitoring['nsi_id'].to_s
        vnf_instances = monitoring['vnf_instances']
        parameters = monitoring['parameters']

        ch = @channel
        vnf_instances.each do |vnf_instance|
            logger.debug 'VNF_Instance_id: ' + vnf_instance['vnfr_id']
            begin
                t = ch.queue(vnf_instance['vnfr_id'], exclusive: false).subscribe do |_delivery_info, _metadata, payload|
                    measurements = JSON.parse(payload)
                    logger.debug 'Receving subcription data of ' + vnf_instance['vnfr_id'].to_s

                    begin
                        @queue = VnfQueue.find_or_create_by(nsi_id: nsi_id, vnfi_id: vnf_instance['vnfr_id'], parameter_id: measurements['type'])
                        @queue.update_attributes(value: measurements['value'], timestamp: measurements['timestamp'], unit: measurements['unit'])
                    rescue => e
                        puts e
                    end
                    begin
                        @list_vnfs_parameters = VnfQueue.where(nsi_id: nsi_id, parameter_id: measurements['type'])
                        # ns_measurement = calculate_sla(@list_vnfs_parameters, vnf_instances, parameters, measurements)
                        if @list_vnfs_parameters.length == vnf_instances.length
                            ns_measurement = calculate_sla(@list_vnfs_parameters, vnf_instances, parameters, measurements, nsi_id)

                            q = ch.queue('ns_monitoring')
                            q.publish(ns_measurement.to_json, persistent: true)

                            VnfQueue.destroy_all(nsi_id: nsi_id, parameter_id: measurements['parameter_id'])
                        else
                            logger.error 'NO equal. Wait next value'
                        end
                    rescue => e
                        puts e
                    end
                end
                logger.debug 'Adding to queue'
                @@testThreads << { vnfi_id: vnf_instance['vnfr_id'], queue: t }
            rescue => e
                puts e
            rescue Interrupt => _
                logger.error 'THREAD INTERRUPTION ...'
                conn.close
            end
        end
    end

    def self.calculate_sla(list_vnfs_parameters, _vnf_instances, parameters, measurements, nsi_id)
        @list_vnfs_parameters = list_vnfs_parameters
        logger.debug @list_vnfs_parameters.to_json
        params = parameters.find_all { |p| p['name'] == measurements['type'] }
        if params.empty?
            calculation = measurements['value']
        else
            logger.debug 'Params (' + measurements['type'].to_s + ') inside the SLA (checking SLA)...'
            values = []
            @list_vnfs_parameters.each do |p|
                values << p['value']
            end
            params.each do |param|
                calculation = ExpressionEvaluatorHelper.calc_expression(param['formula'], values)
                logger.debug 'Calculation response: ' + calculation.to_s
                begin
                    sla = Sla.find_by!(nsi_id: nsi_id)
                    breach = sla.process_reading(param, calculation)
                rescue ActiveRecord::RecordNotFound => e
                    logger.error 'SLA information not found for NSR ' + nsi_id
                end
                # if breach, try with the next
                break if !breach.nil?
            end
        end
        ns_measurement = {
            instance_id: nsi_id,
            type: @queue['parameter_id'],
            unit: @queue['unit'],
            value: calculation,
            timestamp: @queue['timestamp']
        }
        ns_measurement
    end

    def self.startSubcription
        logger.info 'Getting list of instances...'
        begin
            response = RestClient.get Sinatra::Application.settings.manager + '/ns-instances', content_type: :json
            @ns_instances = JSON.parse(response)

            logger.info 'Creating a monitoring thread for each instance...'
            @ns_instances.each do |instance|
                begin
                    monitoring = NsMonitoringParameter.find_by('nsi_id' => instance['id'])
                    nsi_id = monitoring['nsi_id'].to_s
                    logger.info 'Creating thread for NS instance ' + nsi_id.to_s
                    logger.debug monitoring # to remove

                    Thread.new do
                        Thread.current['name'] = nsi_id
                        MonitoringHelper.subcriptionThread(monitoring)
                        Thread.stop
                    end
                rescue Mongoid::Errors::DocumentNotFound => e
                    logger.debug 'No monitoring configuration in the BD for NSr_id ' + instance['id']
                end
            end
        rescue => e
            puts 'Error!'
            puts e
        end
    end

    def destroy_monitoring_data(nsi_id)
        logger.error 'Destroy Monitoring Data of ' + nsi_id
        begin
            response = RestClient.delete settings.ns_monitoring_repo + "/ns-monitoring/#{nsi_id}", content_type: :json
        rescue => e
            logger.error e.response
            # return e.response.code, e.response.body
        end
    end

    def self.logger
        Logging.logger
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
        @logger ||= Logger.new(STDOUT)
    end
end
