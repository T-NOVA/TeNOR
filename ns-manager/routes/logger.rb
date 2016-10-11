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
# @see LoggerController
class LoggerController < TnovaManager

    # @method get_elastic
    # @overload get '/elastic/*'
    # Get logs from elasticsearch/logstash. Different strings allowed in order to filter the required data
    # @param [string]
    get '/' do
        modules = ["ns_manager", "ns_catalogue", "ns_provisioner", "ns_monitoring", "nsd_validator", "vnf_manager", "vnf_catalogue", "vnf_provisioner", "vnf_monitoring", "hot_generator", "vnfd_validator"]
        response = []
        params['from'] = Time.at(params['from'].to_i)
        params['until'] = Time.at(params['until'].to_i)
        if !params['module'].nil?
            if !params['severity'].nil? && params['from'].nil?
                response = Tenor.prefix(params['module']).where(severity: params['severity'].downcase)
            elsif !params['severity'].nil? && !params['from'].nil?
                response = Tenor.prefix(params['module']).where(severity: params['severity'].downcase).where(:time.gte => params['from'], :time.lte => params['until'])
            elsif params['severity'].nil? && !params['from'].nil?
                response = Tenor.prefix(params['module']).where(:time.gte => params['from'], :time.lte => params['until'])
            else
                response = Tenor.prefix(params['module']).all
            end
        else
            if !params['severity'].nil? && params['from'].nil?
                modules.each { |x| response.concat(Tenor.prefix(x).where(severity: params['severity'].downcase))}
            elsif !params['severity'].nil? && !params['from'].nil?
                modules.each { |x| response.concat(Tenor.prefix(x).where(severity: params['severity'].downcase).where(:time.gte => params['from'], :time.lte => params['until']))}
            elsif params['severity'].nil? && !params['from'].nil?
                modules.each { |x| response.concat(Tenor.prefix(x).where(:time.gte => params['from'], :time.lte => params['until']))}
            else
                modules.each { |x| response.concat(Tenor.prefix(x).all)}
            end
        end

        response.to_json
    end
end
