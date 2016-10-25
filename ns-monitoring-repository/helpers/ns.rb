#
# TeNOR - NS Monitoring Repository
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
# @see NsMonitoringRepository
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

    def self.save_monitoring(instance_id, item)
        @db = Sinatra::Application.settings.db
        @db.execute("INSERT INTO nsmonitoring (instanceid, date, metricname, unit, value) VALUES ('#{instance_id}', #{item['timestamp']}, '#{item['type']}', '#{item['unit']}', '#{item['value']}' )")
    end

    def self.delete_monitoring(instance_id)
        @db = Sinatra::Application.settings.db
        @db.execute("DELETE FROM nsmonitoring WHERE instanceid='#{instance_id}'")
    end

    def self.startSubcription
        Thread.new do
            Thread.current['name'] = 'ns_monitoring'
            ch = @channel
            puts ' [*] Waiting for monitoring data.'
            t = ch.queue('ns_monitoring', exclusive: false).subscribe do |_delivery_info, _metadata, payload|
                json = JSON.parse(payload)
                puts 'Saving data for instance: ' + json['instance_id'].to_s
                MonitoringHelper.save_monitoring(json['instance_id'], json)
            end
        end
    end
end
