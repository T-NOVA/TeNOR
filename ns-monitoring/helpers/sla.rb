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
module SlaHelper
    def self.process_breach
        puts 'BREACh. TO REMOOOVE.................'
        logger.info 'SLA Breach!'

        logger.info 'Inform to NS Manager about this.'

        puts Sinatra::Application.settings.manager

        begin
            response = RestClient.get settings.vnf_provisioning + '/vnf-provisioning/vnf-instances/' + vnfr_id, content_type: :json, accept: :json
        rescue => e
            puts e
        end
      end

    # Check if the value is inside the threshold
    # Threshold format: GT(#integer), LE(#integer)...
    def self.check_breach_sla(threshold, value)
        operation = threshold.split('(')[0]
        threshold = threshold.split('(')[1].split(')')[0]
        response = false

        case operation
        when 'GT'
            response = threshold.to_f < value.to_f
        when 'LT'
            response = threshold.to_f > value.to_f
        when 'GE'
            response = threshold.to_f <= value.to_f
        when 'LE'
            response = threshold.to_f >= value.to_f
        when 'EQ'
            response = threshold.to_f == value.to_f
        when 'NE'
            response = threshold.to_f != value.to_f
        end
        response
    end

    def self.logger
        Logging.logger
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
        @logger ||= Logger.new(STDOUT)
    end
end
