#
# TeNOR - VNF Monitoring Repository
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
# @seeVnfMonitoring
module VnfMonitoringHelper

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
      puts "JSON parsing: #{e.to_s}"
      #logger.error "JSON parsing: #{e.to_s}"
      return message, e.to_s + "\n"
    end

    return parsed_message, nil
  end

  def self.save_monitoring(json)
    @db = Sinatra::Application.settings.db
    batch = @db.batch do |b|
      json.each do |item|
        b.add("INSERT INTO vnfmonitoring (instanceid, vduid, date, metricname, unit, value) VALUES ('#{item['instance_id'].to_s}', '#{item['vdu_id'].to_s}', #{item['timestamp']}, '#{item['type']}', '#{item['unit']}', '#{item['value']}' )")
      end
    end
    @db.execute(batch, consistency: :all)
  end

  def self.delete_monitoring(instance_id)
    @db = Sinatra::Application.settings.db
    @db.execute("DELETE FROM vnfmonitoring WHERE instanceid='#{instance_id.to_s}'")
  end

  def self.startSubcription()
    Thread.new {
      Thread.current["name"] = "vnf_repository";
      ch = @channel
      puts " [*] Waiting for logs."
      t = ch.queue("vnf_repository", :exclusive => false).subscribe do |delivery_info, metadata, payload|
        json = JSON.parse(payload)
        puts "Received logs of #{json[0]['instance_id']}"
        VnfMonitoringHelper.save_monitoring(json)
      end
    }
  end
end
