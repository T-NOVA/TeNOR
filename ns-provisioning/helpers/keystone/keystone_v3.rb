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
module Authenticationv3Helper
    def generate_v3_credentials(instance, popUrls, tenant_id, user_id, token)
        @instance = instance
		pop_auth = {}
        begin
            if settings.default_tenant
                pop_auth['username'] = settings.default_user_name
                pop_auth['tenant_name'] = settings.default_tenant_name
                pop_auth['tenant_id'] = getTenantId(popUrls[:keystone], pop_auth['tenant_name'], token)
                pop_auth['user_id'] = getUserId(popUrls[:keystone], pop_auth['username'], token)
                pop_auth['password'] = 'secretsecret'

                if pop_auth['tenant_id'].nil? && pop_auth['user_id'].nil?
                    stack_url, tenant_id, user_id = create_user_and_project(popUrls[:orch], @instance['id'], pop_auth['tenant_name'], pop_auth['username'], pop_auth['password'], tenant_id, token)
                    pop_auth['tenant_id'] = tenant_id
                    pop_auth['user_id'] = user_id
                else
                    pop_auth['tenant_id'] = createTenant(popUrls[:keystone], pop_auth['tenant_name'], token) if pop_auth['tenant_id'].nil?
                    if pop_auth['user_id'].nil?
                        pop_auth['user_id'] = createUser(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'], tenant_id, token)
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
                stack_url,tenant_id, user_id = create_user_and_project(popUrls[:orch], @instance['id'], 'tenor_tenant_' + @instance['id'].to_s, 'user_' + @instance['id'].to_s, 'secretsecret', tenant_id, token)
                pop_auth['tenant_id'] = tenant_id
                pop_auth['user_id'] = user_id
                pop_auth['stack_url'] = stack_url
            end

            if pop_auth['tenant_id'].nil? || pop_auth['user_id'].nil?
                error = 'Tenant or user not created.'
                logger.error error
                @instance.push(audit_log: errors) if errors
                @instance.update_attribute('status', 'ERROR_CREATING')
                return 400, error.to_json
            end

            logger.info 'Created user with admin role.'
            putRoleAdmin(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['user_id'], token)

            logger.info 'Authentication using new user credentials.'
            pop_auth['token'] = authentication_v3_ids(popUrls[:keystone], pop_auth['tenant_id'], pop_auth['username'], pop_auth['password'])
            if pop_auth['token'].nil?
                error = 'Authentication failed.'
                logger.error error
                @instance.push(audit_log: errors) if errors
                @instance.update_attribute('status', 'ERROR_CREATING')
                return 400, error.to_json
            end

            logger.info 'Configuring Security Groups'
            pop_auth['security_group_id'] = configureSecurityGroups(popUrls[:compute], pop_auth['tenant_id'], pop_auth['token'])

            logger.info 'Tenant id: ' + pop_auth['tenant_id']
            logger.info 'Username: ' + pop_auth['username']
        rescue => e
            logger.error e
            error = { 'info' => 'Error creating the Openstack credentials.' }
            logger.error error
            recoverState(@instance, error)
            return 400, error
        end
        pop_auth
    end

    def authentication_v3(keystoneUrl, tenant_name, user, password)
        auth = { auth: { identity: { methods: ['password'], password: { user:{ name: user, domain: { "name": tenant_name }, password: password} } } } }

        begin
            response = RestClient.post keystoneUrl + '/auth/tokens', auth.to_json, content_type: :json
        rescue => e
            logger.error e
            logger.error e.response.body
        end

        auth, errors = parse_json(response)
        return 400, errors if errors

        auth['token']['id'] = response.headers[:x_subject_token]
        auth
      end

    def authentication_v3_ids(keystoneUrl, tenant_id, user_id, password)
        auth = { auth: { tenantId: tenant_id, passwordCredentials: { userId: user_id, password: password } } }

        begin
            response = RestClient.post keystoneUrl + '/tokens', auth.to_json, content_type: :json
        rescue => e
            logger.error e
            logger.error e.response.body
        end

        authentication, errors = parse_json(response)
        return 400, errors if errors

        response.headers[:x_subject_token]
    end
end
