#
# TeNOR - HOT Generator
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

require_relative 'vnfd_to_hot'
require_relative 'hot'
require_relative 'resource'
require_relative 'nsd_to_hot'
require_relative 'wicm_to_hot'
require_relative 'output'
require_relative 'parameter'
require_relative 'custom_exception'
require_relative 'glance/image'
require_relative 'neutron/floating_ip'
require_relative 'neutron/floating_ip_association'
require_relative 'neutron/health_monitor'
require_relative 'neutron/load_balancer'
require_relative 'neutron/network'
require_relative 'neutron/pool'
require_relative 'neutron/port'
require_relative 'neutron/provider_net'
require_relative 'neutron/router'
require_relative 'neutron/router_interface'
require_relative 'neutron/subnet'
require_relative 'heat/wait_condition'
require_relative 'heat/wait_condition_handle'
require_relative 'heat/auto_scaling_group'
require_relative 'heat/scaling_policy'
require_relative 'nova/flavor'
require_relative 'nova/key_pair'
require_relative 'nova/server'
require_relative 'nova/server_group'
require_relative 'generic_resource'

require_relative 'scale_to_hot'
