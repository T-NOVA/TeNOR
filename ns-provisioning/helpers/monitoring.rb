#
# TeNOR - NS Provisioning
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
# @see OrchestratorNsProvisioner
module MonitoringHelper
    # Prepare the monitoring data and sends to the NS Monitoring
    #
    # @param [JSON] message the NSD
    # @param [JSON] message the ns instance
    def monitoringData(nsd, instance)
        monitoring = { nsi_id: instance['id'].to_s }

        vnfs =  nsd['vnfds']
        monitor = nsd['monitoring_parameters']

        paramsVnf = []
        paramsNs = []
        sla = nsd['sla']
        sla.each do |s|
            assurance_parameters = s['assurance_parameters']
            assurance_parameters.each_with_index do |x, i|
                paramsVnf << { id: i + 1, name: x['name'], unit: x['unit'] }
                if x['uid'].nil?
                    paramsNs << { uid: i + 1, name: x['name'], formula: x['formula'], value: x['value'], violations: x['violations'] }
                else
                    paramsNs << { uid: x['uid'], id: i + 1, name: x['name'], formula: x['formula'], value: x['value'], violations: x['violations'] }
                end
            end
        end
        monitoring[:parameters] = paramsNs
        vnf_instances = []
        instance['vnfrs'].each do |x|
            vnf_instances << { id: x['vnfd_id'], parameters: paramsVnf, vnfr_id: x['vnfr_id'] }
        end
        monitoring[:vnf_instances] = vnf_instances

        begin
            response = RestClient.post settings.ns_monitoring + '/ns-monitoring/monitoring-parameters', monitoring.to_json, content_type: :json
        rescue Errno::ECONNREFUSED
            logger.error 'NS Monitoring unreachable'
        rescue => e
            logger.error e
            # halt e.response.code, e.response.body
        end
    end
end
