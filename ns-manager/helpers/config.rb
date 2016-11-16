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
# @see ServiceConfigurationHelper
module ServiceConfigurationHelper
    def self.is_port_open?(ip, port)
        begin
            Timeout.timeout(1) do
                begin
                    s = TCPSocket.new(ip, port)
                    s.close
                    return true
                rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
                    return false
                end
            end
        rescue Timeout::Error
        end
        false
    end

    def self.get_module_by_id(id)
        begin
            s = Service.find(id)
        rescue Mongoid::Errors::DocumentNotFound => e
            return 500, name + ' not registred.'
        end
        s
    end

    def self.get_module(name)
        begin
            s = Service.find_by(name: name)
        rescue Mongoid::Errors::DocumentNotFound => e
            return 500, name + ' not registred.'
        end
        s.host = s.host + ':' + s.port.to_s
        s
    end

    def self.get_module_by_type(type)
        begin
            s = Service.find_by(type: type)
        rescue Mongoid::Errors::DocumentNotFound => e
            return 500, name + ' not registred.'
        end
        s.host + ':' + s.port.to_s
    end

    def self.get_modules
        begin
            services = Service.all
        rescue => e
            logger.error e
        end
        services
    end

    def self.publishModules
        services = get_modules
        services.each do |service|
            logger.debug 'Sending dependencies to ' + service['name']
            if service['type'] == ''
                service['depends_on'].each do |serv|
                    begin
                        logger.debug "Checking if dependant Services of #{serv} is Up and Running...."
                        s = Service.where(name: serv).first
                        next if s.nil?
                        dependant_status = is_port_open?(s['host'], s['port'])
                        if dependant_status == false
                            logger.debug "Service found but is down."
                            s.destroy
                        else
                            dep = { name: s['name'], host: s['host'], port: s['port'], token: s['token'], depends_on: s['depends_on'] }
                            send_dependencies_to_module(service, dep)
                            begin
                                RestClient.post service['host'] + ':' + service['port'] + '/gk_dependencies', dep.to_json, content_type: :json, 'X-Auth-Token' => service['token']
                            rescue => e
                                logger.error e
                            end
                        end
                    rescue Mongoid::Errors::DocumentNotFound => e
                        logger.error 'Service not found.'
                    end
                end
            elsif service['type'] == 'manager'
                send_dependencies_to_manager(service, service['depends_on'])
            end
        end
    end

    def self.send_dependencies_to_module(s, dep)
            begin
                RestClient.post s['host'] + ':' + s['port'] + '/gk_dependencies', dep.to_json, :content_type => :json, 'X-Auth-Token' => s['token']
            rescue => e
                logger.error e
            end
    end

    def self.send_dependencies_to_manager(manager, depends_on)
        depends_on.each do |dep|
            dep = dep[:name] if dep.is_a?(Hash)
            s = Service.where(name: dep).first
            begin
                RestClient.post manager[:host] + ':' + manager[:port].to_s + '/modules/services', s.to_json, :content_type => :json, 'X-Auth-Token' => manager['token']
            rescue => e
                logger.error e
            end
        end
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
        @logger ||= TnovaManager.logger
    end
end
