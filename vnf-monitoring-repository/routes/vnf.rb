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
# @see VnfMonitoringRepository
class VnfMonitoringRepository < Sinatra::Application

  # @method get_vnf_monitoring_data
  # @overload get '/vnf-monitoring/:instance_id/monitoring-data/'
  #	Returns all monitored data
  get '/vnf-monitoring/:instance_id/monitoring-data/' do
    t = []

    if params[:metric] && params[:start] && !params[:end]
      @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' AND metricname='#{params[:metric].to_s}' AND date >= #{params[:start]} ORDER BY metricname DESC LIMIT 2000").fetch { |row| t.push(row.to_hash) }
    elsif params[:metric] && params[:start] && params[:end]
      @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' AND metricname='#{params[:metric].to_s}' AND date >= #{params[:start]} AND date <= #{params[:end]} LIMIT 2000").fetch { |row| t.push(row.to_hash) }
    elsif params[:metric] && params[:end]
      @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' AND metricname='#{params[:metric].to_s}' AND date <= #{params[:end]} ORDER BY metricname DESC LIMIT 2000").fetch { |row| t.push(row.to_hash) }
    elsif params[:metric] && !params[:start]
      @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' AND metricname='#{params[:metric].to_s}' LIMIT 2000").fetch { |row| t.push(row.to_hash) }
    else
      @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' LIMIT 2000").fetch { |row| t.push(row.to_hash) }
    end
    return t.to_json
  end

  # @method get_vnf_monitoring_data_100
  # @overload get '/vnf-monitoring/:instance_id/?:metric/last100/'
  # Returns last 100 values
  get '/vnf-monitoring/:instance_id/monitoring-data/last100/' do
    t = []
    @db.execute("SELECT metricName, date, unit, value FROM vnfmonitoring WHERE instanceid='#{params[:instance_id].to_s}' AND metricname='#{params[:metric].to_s}' ORDER BY metricname DESC LIMIT 100").fetch { |row| t.push(row.to_hash) }
    return t.to_json
  end

  # @method post_vnf_monitoring
  # @overload post '/vnf-monitoring/:instance_id'
  # Inserts monitoring data
  post '/vnf-monitoring/:instance_id' do
    return 415 unless request.content_type == 'application/json'
    json, errors = parse_json(request.body.read)
    return 400, errors.to_json if errors

    instance_id = params[:instance_id]
    VnfMonitoringHelper.save_monitoring(instance_id, json)
    halt 200
  end

  # @method delete_vnf_monitoring
  # @overload delete '/vnf-monitoring/:instance_id'
  # Delete monitoring data
  delete '/vnf-monitoring/:instance_id' do |instance_id|
    VnfMonitoringHelper.delete_monitoring(instance_id)
    halt 200, "Removed monitoring data correctly."
  end

end
