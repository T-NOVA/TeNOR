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
module Authenticationv2Helper
    def generate_v2_credentials(instance, pop_urls, tenant_id, user_id, token)
        logger.info "Generating v2 credentials..."
        @instance = instance
        pop_auth = {}
        begin
            if settings.default_tenant
                pop_auth['username'] = settings.default_user_name
                pop_auth['tenant_name'] = settings.default_tenant_name
                pop_auth['tenant_id'] = getTenantId(pop_urls['keystone'], pop_auth['tenant_name'], token)
                pop_auth['user_id'] = getUserId(pop_urls['keystone'], pop_auth['username'], token)
                pop_auth['password'] = 'secretsecret'

                if pop_auth['tenant_id'].nil? && pop_auth['user_id'].nil?
                    stack_url, tenant_id, user_id = create_user_and_project(pop_urls['heat'], @instance, pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'], tenant_id, token)
                    pop_auth['tenant_id'] = tenant_id
                    pop_auth['user_id'] = user_id
                else
                    pop_auth['tenant_id'] = createTenant(pop_urls['keystone'], pop_auth['tenant_name'], token) if pop_auth['tenant_id'].nil?
                    if pop_auth['user_id'].nil?
                        pop_auth['user_id'] = createUser(pop_urls['keystone'], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], token)
                    else
                        unless settings.default_user_password.nil?
                            pop_auth['password'] = settings.default_user_password
                        end
                    end
                end
            else
                # creating new user and tenant
                pop_auth['tenant_name'] = 'tenor_tenant_' + @instance['id'].to_s
                pop_auth['username'] = 'user_' + @instance['id'].to_s
                pop_auth['password'] = 'secretsecret'
                stack_url, tenant_id, user_id = create_user_and_project(pop_urls['heat'], @instance, 'tenor_tenant_' + @instance['id'].to_s, 'user_' + @instance['id'].to_s, 'secretsecret', tenant_id, token)
                pop_auth['tenant_id'] = tenant_id
                pop_auth['user_id'] = user_id
                pop_auth['stack_url'] = stack_url
            end

            if pop_auth['tenant_id'].nil? || pop_auth['user_id'].nil?
                error = 'Tenant or user not created.'
                logger.error error
                @instance.push(audit_log: error)
                @instance.update_attribute('status', 'ERROR_CREATING')
                return 400, error.to_json
            end

            logger.info 'Created user with admin role.'
            putRoleAdmin(pop_urls['keystone'], pop_auth['tenant_id'], pop_auth['user_id'], token)

            logger.info 'Authentication using new user credentials.'
            pop_auth['token'], errors = authentication_v2_ids(pop_urls['keystone'], pop_auth['tenant_id'], pop_auth['user_id'], pop_auth['password'])
            if errors || pop_auth['token'].nil?
                logger.error errors if errors
                error = 'Authentication failed.'
                logger.error error
                @instance.push(audit_log: errors) if errors
                @instance.update_attribute('status', 'ERROR_CREATING')
                return 400, error.to_json
            end

            logger.info 'Configuring Security Groups'
            pop_auth['security_group_id'] = configureSecurityGroups(pop_urls['compute'], pop_auth['tenant_id'], pop_auth['token'])

            logger.info 'Tenant id: ' + pop_auth['tenant_id']
            logger.info 'Username: ' + pop_auth['username']
        rescue => e
            logger.error e
            error = { 'info' => 'Error creating the Openstack credentials.' }
            logger.error error
            recoverState(@instance, pop_auth, error)
            return 400, error
        end
        pop_auth
    end

    def authentication_v2_with_token(keystoneUrl, tenant_name, token)
        auth = { auth: { tenantName: tenant_name, token: { id: token } } }

        begin
            response = RestClient.post keystoneUrl + '/tokens', auth.to_json, content_type: :json
        rescue => e
            logger.error e
            logger.error e.response if !e.response.nil?
            return 400, e
        end

        authentication, errors = parse_json(response)
        return 400, errors if errors

        authentication
    end

    def authentication_v2(keystoneUrl, tenant_name, user, password)
        auth = { auth: { tenantName: tenant_name, passwordCredentials: { username: user, password: password } } }

        begin
            response = RestClient.post keystoneUrl + '/tokens', auth.to_json, content_type: :json
        rescue => e
            logger.error e
            logger.error e.response if !e.response.nil?
            return 400, e
        end

        authentication, errors = parse_json(response)
        return 400, errors if errors

        authentication
    end

    def authentication_v2_ids(keystoneUrl, tenant_id, user_id, password)
        auth = { auth: { tenantId: tenant_id, passwordCredentials: { userId: user_id, password: password } } }

        begin
            response = RestClient.post keystoneUrl + '/tokens', auth.to_json, content_type: :json
        rescue => e
            logger.error e
            logger.error e.response.body
            return 400, e.response.body
        end

        authentication, errors = parse_json(response)
        return 400, errors if errors

        authentication['access']['token']['id']
    end

    def createTenant(keystoneUrl, projectName, token)
        project = { tenant: { description: 'Tenant created by TeNOR', enabled: true, name: projectName } }

        begin
            return getTenantId(keystoneUrl, tenantName, token)
        rescue => e
            begin
                response = RestClient.post keystoneUrl + '/tenants', project.to_json, :content_type => :json, :'X-Auth-Token' => token
            rescue => e
                logger.error e
                logger.error e.response.body
            end

            project, errors = parse_json(response)
            return 400, errors if errors

            return project['tenant']['id']
        end
    end

    # deprecated
    def createUser(keystoneUrl, projectId, userName, password, token)
        user = { user: { email: userName + '@tenor-tnova.eu', enabled: true, name: userName, password: password, tenantId: projectId } }
        user_id = getUserId(keystoneUrl, userName, token)
        if user_id.nil?
            begin
                response = RestClient.post keystoneUrl + '/users', user.to_json, :content_type => :json, :'X-Auth-Token' => token
            rescue => e
                logger.error e
                logger.error e.response.body
            end
            user, errors = parse_json(response)
            return 400, errors if errors

            return user['user']['id']
        else
            return user_id
        end
    end

    def getTenantId(keystoneUrl, tenantName, token)
        begin
            response = RestClient.get keystoneUrl + '/tenants', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end

        tenants, errors = parse_json(response)
        tenant = tenants['tenants'].find { |tenant| tenant['name'] == tenantName }
        return tenant['id'] unless tenant.nil?
    end

    def getUserId(keystoneUrl, username, token)
        begin
            response = RestClient.get keystoneUrl + '/users', :content_type => :json, :'X-Auth-Token' => token
        rescue => e
            logger.error e
            logger.error e.response.body
        end

        users, errors = parse_json(response)
        user = users['users'].find { |user| user['username'] == username }
        return user['id'] unless user.nil?
    end
end
