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
# @see OrchestratorHotGenerator
module CommonMethods

	# Generate a HOT template
	#
	# @param [Hash] vnfd the VNFD
	# @param [String] flavour_key the T-NOVA flavour
	# @param [Array] networks_id the IDs of the networks created by the NS Manager
	# @param [String] security_group_id the ID of the T-NOVA security group
	# @param [String] vnfr_id the ID of the VNFr
	# @param [String] dns the DNS
	# @return [Hash] the generated hot template
	def self.generate_hot_template(vnfd, flavour_key, networks_id, routers_id, security_group_id, vnfr_id, dns, public_network_id, flavours)
		hot = VnfdToHot.new(vnfd['name'].delete(" "), vnfd['description'], public_network_id)

		begin
			hot.build(vnfd, flavour_key, networks_id, routers_id, security_group_id, vnfr_id, dns, flavours)
		rescue CustomException::NoExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidTemplateFileFormat => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::NoFlavorError => e
			logger.error e.message
			halt 400, e.message
		end
	end

	def self.generate_hot_template_scaling(vnfd, flavour_key, networks_id, security_group_id, public_network_id, vdus_deployed_info)
		hot = ScaleToHot.new(vnfd['name'], vnfd['description'], public_network_id)

		begin
			hot.build(vnfd, flavour_key, networks_id, security_group_id, vdus_deployed_info)
		rescue CustomException::NoExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidExtensionError => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::InvalidTemplateFileFormat => e
			logger.error e.message
			halt 400, e.message
		rescue CustomException::NoFlavorError => e
			logger.error e.message
			halt 400, e.message
		end
	end

	# Generate a Network HOT template
	#
	# @param [Hash] nsd the NSD
	# @param [String] public_ip the ID of the public network
	# @param [String] dns_server the DNS Server to add to the networks
	# @param [String] flavour the T-NOVA flavour
	# @return [Hash] the generated networks hot template
	def self.generate_network_hot_template(nsd, public_net_id, dns_server, flavour, nsr_id)
		hot = NsdToHot.new(nsd['id'], nsd['name'])

    begin
      hot.build(nsd, public_net_id, dns_server, flavour, nsr_id)
    rescue CustomException::NoExtensionError => e
      logger.error e.message
      halt 400, e.message
    rescue CustomException::InvalidExtensionError => e
      logger.error e.message
      halt 400, e.message
    rescue CustomException::InvalidTemplateFileFormat => e
      logger.error e.message
      halt 400, e.message
    rescue CustomException::NoFlavorError => e
      logger.error e.message
      halt 400, e.message
    end
	end

	# Generate a WICM HOT template
	#
	# @param [Hash] provider_info information about the provider networks
	# @return [Hash] the generated wicm hot template
	def self.generate_wicm_hot_template(provider_info)
		hot = WicmToHot.new('WICM', 'Resources for WICM and SFC integration')

		hot.build(provider_info)
	end

	# Generate a Netfloc HOT template
	#
	# @param [Hash] vnffgd
	# @param [Hash] odl_username ODL username
	# @param [Hash] odl_password ODL password
	# @param [Hash] netfloc_ip_port Netfloc IP and Port
	# @return [Hash] the generated netfloc hot template
	def self.generate_netfloc_hot_template(ports, odl_username, odl_password, netfloc_ip_port)
		hot = NetflocToHot.new('Netfloc', 'Resources for Netfloc integration')

		hot.build(ports, odl_username, odl_password, netfloc_ip_port)
	end

	# Generate a User HOT template
	#
	# @param [Hash] credentials_info information about the user and project
	# @return [Hash] the generated user hot template
	def self.generate_user_hot_template(credentials_info)
		hot = UserToHot.new('User', 'Resources for User and tenant')

		hot.build(credentials_info)
	end

	def self.is_num?(str)
		!!Integer(str)
	rescue ArgumentError, TypeError
		false
	end

  def self.logger
    Logging.logger
  end

  # Global, memoized, lazy initialized instance of a logger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
