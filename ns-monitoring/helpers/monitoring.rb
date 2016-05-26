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
      logger.error "JSON parsing: #{e.to_s}"
      return message, e.to_s + "\n"
    end

    return parsed_message, nil
  end

  def create_monitoring_metric_object(json)

    monitoring_metrics = NsMonitoringParameter.new(json)
    return monitoring_metrics
  end

  # Subcription thread method
  #
  # @param [JSON] message monitoring information
  def self.subcriptionThread(monitoring)
    logger.info "Subcription thread"
    logger.error "NSr: " + monitoring['nsi_id'].to_s
    nsr_id = monitoring['nsi_id'].to_s
    vnf_instances = monitoring['vnf_instances']

    ch = @channel

    logger.debug " [*] Waiting for logs."

    logger.debug vnf_instances

    vnf_instances.each do |vnf_instance|
      puts "VNF_Instance_id:"
      puts vnf_instance['vnfr_id'] #vnf_id
      puts vnf_instance['vnfr_id']
      begin
        puts "Create another subcription"
        t = ch.queue(vnf_instance['vnfr_id'], :exclusive => false).subscribe do |delivery_info, metadata, payload|
          puts "Receving subcription data " + vnf_instance['vnfr_id'].to_s
          measurements = JSON.parse(payload)
          puts measurements
          puts "Mon Metrics:"
          nsi_id = nsr_id

          begin
            @queue = VnfQueue.find_or_create_by(:nsi_id => nsi_id, :vnfi_id => vnf_instance['vnfr_id'], :parameter_id => measurements['type'])
            @queue.update_attributes({:value => measurements['value'], :timestamp => measurements['timestamp'], :unit => measurements['unit']})
          rescue => e
            puts e
          end
          puts @queue
          begin
            @list_vnfs_parameters = VnfQueue.where(:nsi_id => nsi_id, :parameter_id => measurements['type'])
            if @list_vnfs_parameters.length == vnf_instances.length
              puts "Lisf of vnfs_params is equal."
              puts "Send to Expression Evaluator."

              puts @queue['value']
              puts @queue
              puts @queue['parameter_id']

              expression_response = 10

              ns_measurement = {
                  :instance_id => nsi_id,
                  :type => @queue['parameter_id'],
                  :unit => @queue['unit'],
                  :value => expression_response,
                  :timestamp => @queue['timestamp']
              }
              puts ns_measurement

              q = ch.queue("ns_monitoring")
              puts "Publishing...."
              q.publish(ns_measurement.to_json, :persistent => true)

              #remove database
              VnfQueue.destroy_all(:nsi_id => nsi_id, :parameter_id => measurements['parameter_id'])
            else
              puts "NO equal. Wait next value"
            end
          rescue => e
            puts e
          end

        end
        puts "Adding queue????"
        @@testThreads << {:vnfi_id => vnf_instance['vnfr_id'], :queue => t}
      rescue Interrupt => _
        puts "INTERRUPTION.........."
        conn.close
      end
    end
  end

  def self.startSubcription()
    puts "Getting list of instances..."
    begin
      response = RestClient.get Sinatra::Application.settings.ns_provisioner + '/ns-instances', :content_type => :json
      #puts response
      @ns_instances = JSON.parse(response)

      puts "Getting monitoring for each instance..."
      #for each instance, create a thread for subcribe to monitoring
      @ns_instances.each do |instance|
        #get mnonitoring data for instance
        puts instance['id']
        begin
          monitoring = NsMonitoringParameter.find_by("nsi_id" => instance['id'])
          nsi_id = monitoring['nsi_id'].to_s
          puts "Creating thread..."
          puts monitoring

          Thread.new {
            Thread.current["name"] = nsi_id;
            MonitoringHelper.subcriptionThread(monitoring)
            Thread.stop
          }
        rescue Mongoid::Errors::DocumentNotFound => e
          puts "No monitoring data in the BD"
          #halt 400, "Monitoring Metric instance no exists"
        end
      end
    rescue => e
      puts "Error!"
      puts e
    end
  end
end