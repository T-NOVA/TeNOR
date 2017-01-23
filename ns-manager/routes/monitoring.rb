#
# TeNOR - NS Manager
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
# @see TnovaManager
class NsMonitoring < TnovaManager
    # @method get_instances_monitoring_data
    # @overload get '/instances/:instance_id/monitoring-data/'
    # Get monitoring data given instance type and/or metrics
    # @param [string] instance_type
    # @param [string] instance_id
    # @param [string] metric
    get '/:instance_id/monitoring-data/' do |instance_id|
        if params['instance_type'] == 'ns'
            monitoring, errors = ServiceConfigurationHelper.get_module('ns_monitoring')
            halt 500, errors if errors
            composedUrl = "/ns-monitoring/#{instance_id}/monitoring-data/?" + request.env['QUERY_STRING']
        elsif params['instance_type'] == 'vnf'
            monitoring, errors = ServiceConfigurationHelper.get_module('vnf_manager')
            halt 500, errors if errors
            composedUrl = "/vnf-monitoring/#{instance_id}/monitoring-data/?" + request.env['QUERY_STRING']
        end

        begin
            response = RestClient.get monitoring.host + composedUrl.to_s, 'X-Auth-Token' => monitoring.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'NS Monitoring unreachable'
        rescue => e
            logger.error e
            # halt e.response.code, e.response.body
        end

        return 200 if response.nil?
        return 200, response.body
    end

    # @method get_monitoring_data_last100
    # @overload get '/instances/:instance_id/monitoring-data/last100'
    # Get last 100 values
    # @param [string] Instance id
    get '/:instance_id/monitoring-data/last100/' do |instance_id|
        if params['instance_type'] == 'ns'
            monitoring, errors = ServiceConfigurationHelper.get_module('ns_monitoring')
            halt 500, errors if errors
            composedUrl = "/ns-monitoring/#{instance_id}/monitoring-data/last100/?" + request.env['QUERY_STRING']
        elsif params['instance_type'] == 'vnf'
            monitoring, errors = ServiceConfigurationHelper.get_module('vnf_manager')
            halt 500, errors if errors
            composedUrl = "/vnf-monitoring/#{instance_id}/monitoring-data/last100/?" + request.env['QUERY_STRING']
        end

        begin
            response = RestClient.get monitoring.host + composedUrl.to_s, 'X-Auth-Token' => monitoring.token, :content_type => :json
        rescue Errno::ECONNREFUSED
            halt 500, 'NS Monitoring unreachable'
        rescue => e
            logger.error e.response
            halt e.response.code, e.response.body
        end

        return response
    end
end
