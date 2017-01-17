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
class NsMonitoringRepository < Sinatra::Application
    # @method get_ns_monitoring_data
    # @overload get '/ns-monitoring/:instance_id/monitoring-data/'
    #	Returns all monitored data
    get '/ns-monitoring/:instance_id/monitoring-data/' do
        t = []
        @db = settings.db
        if params[:metric] && params[:start] && !params[:end]
            @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' AND metricname='#{params[:metric]}' AND date >= #{params[:start]} ORDER BY metricname DESC LIMIT 2000").each { |row| t.push(row.to_hash) }
        elsif params[:metric] && params[:start] && params[:end]
            @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' AND metricname='#{params[:metric]}' AND date >= #{params[:start]} AND date <= #{params[:end]} LIMIT 2000").each { |row| t.push(row.to_hash) }
        elsif params[:metric] && params[:end]
            @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' AND metricname='#{params[:metric]}' AND date <= #{params[:end]} ORDER BY metricname DESC LIMIT 2000").each { |row| t.push(row.to_hash) }
        elsif params[:metric] && !params[:start]
            @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' AND metricname='#{params[:metric]}' LIMIT 2000").each { |row| t.push(row.to_hash) }
        else
            @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' LIMIT 2000").each { |row| t.push(row.to_hash) }
        end
        return t.to_json
    end

    # @method get_ns_monitoring_data_100
    # @overload get '/ns-monitoring/:instance_id/?:metric/last100/'
    # Returns last 100 values
    get '/ns-monitoring/:instance_id/monitoring-data/last100/' do
        t = []
        @db = settings.db
        @db.execute("SELECT * FROM nsmonitoring WHERE instanceid='#{params[:instance_id]}' AND metricname='#{params[:metric]}' ORDER BY metricname DESC LIMIT 100").each { |row| t.push(row.to_hash) }
        return t.to_json
    end

    # @method post_ns_monitoring_id
    # @overload post '/ns-monitoring/:instance_id'
    # Inserts monitoring data
    post '/ns-monitoring/:instance_id' do
        return 415 unless request.content_type == 'application/json'
        json, errors = parse_json(request.body.read)
        return 400, errors.to_json if errors

        instance_id = params[:instance_id]
        MonitoringHelper.save_monitoring(instance_id, json)
        halt 200
    end

    # @method delete_ns_monitoring
    # @overload delete '/ns-monitoring/:instance_id'
    # Delete monitoring data
    delete '/ns-monitoring/:instance_id' do |instance_id|
        MonitoringHelper.delete_monitoring(instance_id)
        halt 200, 'Removed monitoring data correctly.'
    end
end
