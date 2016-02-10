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
class VnfdToHot

	# Initializes VnfdToHot object
	#
	# @param [String] name the name for the HOT
	# @param [String] description the description for the HOT
	def initialize(name, description)
		@hot = Hot.new(description)
		@name = name
		@outputs = {}
	end

	# Converts VNFD to HOT
	#
	# @param [Hash] vnfd the VNFD
	# @param [String] tnova_flavour the T-NOVA flavour to generate the HOT for
	# @param [Array] networks_id the IDs of the networks created by NS Manager
	# @param [String] security_group_id the ID of the T-NOVA security group
	# @return [HOT] returns an HOT object
	def build(vnfd, tnova_flavour, networks_id, security_group_id)
		# Parse needed outputs
		parse_outputs(vnfd['vnf_lifecycle_events'].find{|lifecycle| lifecycle['flavor_id_ref'] == tnova_flavour}['events'])

		# Get T-NOVA deployment flavour
		deployment_information = vnfd['deployment_flavours'].detect{|flavour| flavour['id'] == tnova_flavour}
		raise CustomException::NoFlavorError, "Flavor #{tnova_flavour} not found" if deployment_information.nil?

		# Get the vlinks references for the deployment flavour
		vlinks = deployment_information['vlink_reference']

		deployment_information['vdu_reference'].each do |vdu_ref|
			# Get VDU for deployment
			vdu = vnfd['vdu'].detect { |vdu| vdu['id'] == vdu_ref }

			#image_name = create_image(vdu)
			flavor_name = create_flavor(vdu)

			ports = create_ports(vdu['connection_points'], vnfd['vlinks'], networks_id, security_group_id)
			#ports = create_ports(vdu_ref, vdu['vnfc']['id'], vdu['vnfc']['networking'])

			#create_server(vdu, image_name, flavor_name, ports)
			create_server(vdu, flavor_name, ports)
		end

		@hot
	end

	# Parse the outputs from the VNFD and builds an outputs hash
	#
	# @param [Hash] events the VNF lifecycle events
	def parse_outputs(events)
		outputs = []
		events.each do |event, event_info|
			unless event_info.nil? || event_info['template_file'].nil?
				raise CustomException::InvalidTemplateFileFormat, "Template file format not supported" unless event_info['template_file_format'].downcase == 'json'
				JSON.parse(event_info['template_file']).each do |id, output|
					unless outputs.include?(output)
						outputs << output
						match = output.match(/^get_attr\[(.*), *(.*)\]$/i).to_a
						if @outputs.has_key?(match[2])
							@outputs[match[2]] << match[1]
						else
							@outputs[match[2]] = [match[1]]
						end
					end
				end
			end
		end
	end

	# Creates an HEAT image resource from the VNFD
	#
	# @param [Hash] vdu the VDU from the VNFD
	# @return [String] the name of the created resource
	def create_image(vdu)
		name = get_resource_name
		
		raise CustomException::NoExtensionError, "#{vdu['vm_image']} does not have a file extension" if vdu['vm_image_format'].empty?
		raise CustomException::InvalidExtensionError, "#{vdu['vm_image']} has an invalid extension. Allowed extensions: ami, ari, aki, vhd, vmdk, raw, qcow2, vdi and iso" unless ['ami', 'ari', 'aki', 'vhd', 'vmdk', 'raw', 'qcow2', 'vdi', 'iso'].include? vdu['vm_image_format']

		@hot.resources_list << Image.new(name, vdu['vm_image_format'], vdu['vm_image'])
		name
	end

	# Creates an HEAT port resource from the VNFD
	#
	# @param [String] vdu_id the VDU ID from the VNFD
	# @param [String] vnfc_id the VNFC ID from the VNFD
	# @param [Array] vnfcs the list of VNFCS for the VDU
	# @param [Array] networks_id the IDs of the networks created by NS Manager
	# @param [String] security_group_id the ID of the T-NOVA security group
	# @return [Array] a list of ports
	def create_ports(connection_points, vlinks, networks_id, security_group_id)
		ports = []

		connection_points.each do |connection_point|
			vlink = vlinks.find {|vlink| vlink['id'] == connection_point['vlink_ref']}
			network_id = networks_id.find{ |network| network['alias'] == vlink['alias'] }['id']
			port_name = "#{connection_point['id']}"
			ports << { port: {get_resource: port_name} }
			@hot.resources_list << Port.new(port_name, network_id, security_group_id)

			# Check if it's necessary to create an output for this resource
			if @outputs.has_key?('ip') && @outputs['ip'].include?(port_name)
				@hot.outputs_list << Output.new("#{port_name}#ip", "#{port_name} IP address", {get_attr: [port_name, 'fixed_ips', 0, 'ip_address']})
			end

			# Check if the port has a Floating IP
			if vlink['access']
				floating_ip_name = get_resource_name
				# TODO: Receive the floating ip pool name?
				@hot.resources_list << FloatingIp.new(floating_ip_name, 'public')
				@hot.resources_list << FloatingIpAssociation.new(get_resource_name, {get_resource: floating_ip_name}, {get_resource: port_name})
				@hot.outputs_list << Output.new("#{port_name}#floating_ip", "#{port_name} Floating IP", {get_attr: [floating_ip_name, 'floating_ip_address']})
			end
		end

		ports
	end
=begin
	def create_ports(vdu_id, vnfc_id, vnfcs)
		ports = []

		vnfcs.each do |vnfc|
			port_name = "#{vnfc_id}:#{vnfc['connection_point_id']}"
			ports << { port: {get_resource: port_name} }
			@hot.resources_list << Port.new(port_name, vnfc['vitual_link_reference'])

			# Check if is necessary to create an output for this resource
			if @outputs.has_key?('ip') && @outputs['ip'].include?(port_name)
				@hot.outputs_list << Output.new("#{vnfc_id}:#{vnfc['connection_point_id']}#ip", "#{vdu_id} IP address in #{vnfc['vitual_link_reference']} network", {get_attr: [port_name, 'fixed_ips', 0, 'ip_address']})
			end
			
			if vnfc['type'].downcase == 'floating'
				floating_ip_name = get_resource_name
				# TODO: Receive the floating ip pool name?
				@hot.resources_list << FloatingIp.new(floating_ip_name, 'public')
				@hot.resources_list << FloatingIpAssociation.new(get_resource_name, {get_resource: floating_ip_name}, {get_resource: port_name})
				@hot.outputs_list << Output.new("#{vdu_id}#floating_ip", "#{vdu_id} Floating IP", {get_attr: [floating_ip_name, 'floating_ip_address']})
			end
		end

		ports
	end
=end

	# Creates an HEAT flavor resource from the VNFD
	#
	# @param [Hash] vdu the VDU from the VNFD
	# @return [String] the name of the created resource
	def create_flavor(vdu)
		name = get_resource_name
		storage_info = vdu['resource_requirements']['storage']
		@hot.resources_list << Flavor.new(
			name,
			unit_converter(storage_info['size'], storage_info['size_unit'], 'gb'),
			unit_converter(vdu['resource_requirements']['memory'], vdu['resource_requirements']['memory_unit'], 'mb'),
			vdu['resource_requirements']['vcpus'])
		name
	end

	# Creates an HEAT server resource from the VNFD
	#
	# @param [Hash] vdu the VDU from the VNFD
	# @param [String] image_name the image resource name
	# @param [String] flavour_name the flavour resource name
	# @param [Array] ports list of the ports resource
	#def create_server(vdu, image_name, flavour_name, ports)
	def create_server(vdu, flavour_name, ports)
		@hot.resources_list << Server.new(
			vdu['id'],
			{get_resource: flavour_name},
			'c2495efa-e331-4f49-b4b5-e35415a0aaeb',
			ports)
		@hot.outputs_list << Output.new("#{vdu['id']}#id", "#{vdu['id']} ID", {get_resource: vdu['id']})
	end

	# Generates a new resource name
	#
	# @return [String] the generated resource name
	def get_resource_name
		@name + '_' + @hot.resources_list.length.to_s unless @name.empty?
	end

	# Converts a value to another unit
	#
	# @param [Numeric] value the value to convert
	# @param [String] input_unit the unit to convert from
	# @param [String] output_unit the unit to convert to
	# @return [Numeric] the converted value
	def unit_converter(value, input_unit, output_unit)
		return 0 if value == 0
		return value if input_unit.downcase == output_unit.downcase

		if input_unit.downcase == 'gb'
			if output_unit.downcase == 'mb'
				return value * 1024
			end
		else
			if input_unit.downcase == 'mb'
				if output_unit.downcase == 'gb'
					return value / 1024
				end
			else
				if input_unit.downcase == 'tb'
					if output_unit.downcase == 'gb'
						return value * 1024
					end
				end
			end
		end
	end

end