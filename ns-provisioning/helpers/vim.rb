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
# @see NSProvisioner
module VimHelper
    def getAdminRole(keystoneUrl, token)
        begin
            response = RestClient.get keystoneUrl + '/OS-KSADM/roles', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end
        roles, errors = parse_json(response)
        return 400, errors if errors

        role = roles['roles'].find { |role| role['name'] == 'admin' }
        role['id']
    end

    def putRoleAdmin(keystoneUrl, tenant_id, user_id, token)
        role_id = getAdminRole(keystoneUrl, token)
        begin
            response = RestClient.put keystoneUrl + '/tenants/' + tenant_id + '/users/' + user_id + '/roles/OS-KSADM/' + role_id, '', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end
        status 200
    end

    def publicNetworkId(neutronUrl, token)
        begin
            response = RestClient.get neutronUrl + '/networks', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end
        networks, errors = parse_json(response)
        network = networks['networks'].find { |role| role['name'] == 'public' }
        if network.nil?
            network = networks['networks'].find { |role| role['router:external'] }
        end
        return 400, 'No external network defined in Openstack.' if network.nil?
        network['id']
    end

    def createSecurityGroup(computeUrl, tenant_id, token)
        securityGroup = {
            security_group: {
                name: 'tenor_security_group_' + tenant_id,
                description: 'A security group created by Tenor'
            }
        }

        begin
            response = RestClient.post computeUrl + '/' + tenant_id + '/os-security-groups', securityGroup.to_json, :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end
        sec, error = parse_json(response)
        return nil if sec.nil?
        sec['security_group']['id']
    end

    def addRulesToTenant(computeUrl, tenant_id, security_group_id, protocol, token, from, to)
        role = {
            security_group_rule: {
                ip_protocol: protocol,
                from_port: from,
                to_port: to,
                cidr: '0.0.0.0/0',
                parent_group_id: security_group_id
            }
        }

        begin
            response = RestClient.post computeUrl + '/' + tenant_id + '/os-security-group-rules', role.to_json, :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end
        status 200
    end

    def deleteSecurityGroup(computeUrl, tenant_id, sec_group_id, token)
        response = RestClient.delete computeUrl + '/' + tenant_id + '/os-security-groups/' + sec_group_id, :content_type => :json, :'X-Auth-Token' => token
    rescue => e
        logger.error e
        logger.error e.response.body
    end

    def getSecurityGroups(computeUrl, tenant_id, token)
        begin
            response = RestClient.get computeUrl + '/' + tenant_id + '/os-security-groups', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
            return nil
        end
        sec, error = parse_json(response)
        sec
    end

    def configureSecurityGroups(computeUrl, tenant_id, token)
        vim_security_groups = getSecurityGroups(computeUrl, tenant_id, token)
        return nil if vim_security_groups.nil?
        security_group_id = nil
        if !settings.default_tenant_name.nil?
            security_group_id = vim_security_groups['security_groups'][0]['id']
        elsif secuGroupId = createSecurityGroup(computeUrl, tenant_id, token)
            security_group_id = secuGroupId
            addRulesToTenant(computeUrl, tenant_id, secuGroupId, 'TCP', token, 1, 65_535)
            addRulesToTenant(computeUrl, tenant_id, secuGroupId, 'UDP', token, 1, 65_535)
            addRulesToTenant(computeUrl, tenant_id, secuGroupId, 'ICMP', token, -1, -1)
        end
        security_group_id
    end
end
