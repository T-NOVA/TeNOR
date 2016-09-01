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
  # @param [JSON] message the NSR id
  # @param [JSON] message the ns instance
  # @return [Hash, nil] if the parsed message is a valid JSON
  # @return [Hash, String] if the parsed message is an invalid JSON
  def monitoringData(nsd, nsi_id, instance)

    monitoring = {:nsi_id => nsi_id}

    vnfs =  nsd['vnfds']
    monitor =  nsd['monitoring_parameters']

    paramsVnf = []
    paramsNs = []
    sla = nsd['sla']
    sla.each {|s|
      assurance_parameters = s['assurance_parameters']
      assurance_parameters.each_with_index {|x, i|
        paramsVnf << {:id => i+1, :name => x['name'], :unit => x['unit']}
        paramsNs << {:id => i+1, :name => x['name'], :formula => x['formula']}
      }
    }
    monitoring[:parameters] = paramsNs
    vnf_instances = []
    instance['vnfrs'].each {|x|
      vnf_instances << {:id => x['vnfd_id'], :parameters => paramsVnf, :vnfr_id => x['vnfr_id']}
    }
    monitoring[:vnf_instances] = vnf_instances

    #puts JSON.pretty_generate(monitoring)

    begin
      response = RestClient.post settings.ns_monitoring + '/ns-monitoring/monitoring-parameters', monitoring.to_json, :content_type => :json
    rescue Errno::ECONNREFUSED
      puts 'NS Monitoring unreachable'
#      halt 500, 'NS Monitoring unreachable'
    rescue => e
      logger.error e.response
      #halt e.response.code, e.response.body
    end

    #return monitoring
  end

  def sla_enforcement(nsd, instance_id)
    parameters = []

    nsd['sla'].each do |sla|
      #sla['id']
      sla['assurance_parameters'].each do |assurance_parameter|
        parameters.push({:param_name => assurance_parameter['param_name'], :minimum => nil, :maximum => nil})
      end

    end
    sla = {:nsi_id => instance_id, :parameters => parameters}
    begin
      response = RestClient.post settings.sla_enforcement + "/sla-enforcement/slas", sla.to_json, :content_type => :json
    rescue => e
      logger.error e
      if (defined?(e.response)).nil?
        halt 503, "SLA-Enforcement unavailable"
      end
      halt e.response.code, e.response.body
    end
  end
end