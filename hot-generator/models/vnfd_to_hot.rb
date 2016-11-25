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
    def initialize(name, description, public_network_id)
        @hot = Hot.new(description)
        @name = name
        @outputs = {}
        @type = ''
        @vnfr_id = ''
        @public_network_id = public_network_id
    end

    # Converts VNFD to HOT
    #
    # @param [Hash] vnfd the VNFD
    # @param [String] tnova_flavour the T-NOVA flavour to generate the HOT for
    # @param [Array] networks_id the IDs of the networks created by NS Manager
    # @param [String] security_group_id the ID of the T-NOVA security group
    # @return [HOT] returns an HOT object
    def build(vnfd, tnova_flavour, networks_id, routers_id, security_group_id, vnfr_id, dns, flavours)
        # Parse needed outputs
        parse_outputs(vnfd['vnf_lifecycle_events'].find { |lifecycle| lifecycle['flavor_id_ref'] == tnova_flavour }['events'])

        @type = vnfd['type']
        @vnfr_id = vnfr_id

        key = create_key_pair(SecureRandom.urlsafe_base64(9))
        router_id = routers_id[0]['id']

        # Get T-NOVA deployment flavour
        deployment_information = vnfd['deployment_flavours'].detect { |flavour| flavour['id'] == tnova_flavour }
        raise CustomException::NoFlavorError, "Flavor #{tnova_flavour} not found" if deployment_information.nil?

        # Get the vlinks references for the deployment flavour
        vlinks = deployment_information['vlink_reference']

        networks_id = []
        router_interfaces = []

        vlinks.each do |vlink|
            vlink_json = vnfd['vlinks'].detect { |vl| vl['id'] == vlink }
            if !vlink_json['existing_net_id'].nil?
                networks_id << { 'id' => vlink, 'alias' => vlink_json['alias'], 'heat_id' => vlink_json['existing_net_id'] }
            else
                net_name, router_interface = create_networks(vlink_json, dns, router_id)
                networks_id << { 'id' => vlink, 'alias' => vlink_json['alias'], 'heat' => vlink }
                router_interfaces << router_interface
            end
        end

        deployment_information['vdu_reference'].each do |vdu_ref|
            # Get VDU for deployment
            vdu = vnfd['vdu'].detect { |vdu| vdu['id'] == vdu_ref }

            image_name = if vdu['vm_image_format'] == 'openstack_id'
                             vdu['vm_image']
                         else
                             { get_resource: create_image(vdu) }
                         end
            if flavours.detect { |fl| fl['id'] == vdu_ref }
                flavor_name = flavours.find { |fl| fl['id'] == vdu_ref }['flavour_id']
            else
                flavor_name = { get_resource: create_flavor(vdu) }
            end

            # ports = create_ports(vdu['id'], vdu['connection_points'], vnfd['vlinks'], networks_id, security_group_id)
            nets = []
            vdu['connection_points'].each do |connection_point|
                l = networks_id.find { |vlink| vlink['id'] == connection_point['vlink_ref'] }
                nets << { network: { get_resource: l['heat'] } }
            end

            # create AutoScalingGroup if the VNF can scale
            if vdu['scale_in_out']['maximum'] > 10
                # generate template for server
                nested_template = generate_nested_template(vdu, vnfd, networks_id, security_group_id, nets, router_interfaces, router_id)

                # save template in folder
                name = vnfd['id'].to_s
                filename = 'assets/templates/' + name + '.yaml'
                File.open(filename, 'w') { |file| file.write(nested_template.to_yaml) }

                url = HotGenerator.manager + '/files/' + name + '.yaml'
                properties = {
                    image: image_name,
                    flavor: flavor_name
                }

                networks_id.each do |net|
                    properties[net['heat']] = { 'get_resource' => net['heat'] }
                end
                router_interfaces.each do |iface|
                    properties[iface] = { 'get_resource' => iface }
                end
                # properties['depends_on'] = router_interfaces

                scaled_resource = GenericResource.new(vdu['id'], url, properties, router_interfaces)
                auto_scale_group = create_autoscale_group(60, vdu['scale_in_out']['maximum'], vdu['scale_in_out']['minimum'], 1, scaled_resource)
                scale_out_policy = create_scale_policy(auto_scale_group, 1)
                scale_in_policy = create_scale_policy(auto_scale_group, -1)
                @hot.outputs_list << Output.new("#{vdu['id']}#scale_out_url", 'Url of scale out.', get_attr: [scale_out_policy, 'alarm_url'])
                @hot.outputs_list << Output.new("#{vdu['id']}#scale_in_url", 'Url of scale in.', get_attr: [scale_in_policy, 'alarm_url'])
                @hot.outputs_list << Output.new("#{vdu['id']}#scale_group", "#{vdu['id']} ID", get_resource: auto_scale_group)
            else
                ports = create_ports(vdu['id'], vdu['connection_points'], vnfd['vlinks'], networks_id, security_group_id, router_interfaces)
                create_server(vdu, image_name, flavor_name, ports, key, false)
            end
        end

        # puts @hot.to_yaml

        @hot
    end

    def generate_nested_template(vdu, vnfd, networks_id, security_group_id, _nets, router_interfaces, _router_id)
        hot = Hot.new('server')
        hot.parameters_list = []
        outputs_list = {}
        hot.parameters_list << Parameter.new('image', '', 'string')
        hot.parameters_list << Parameter.new('flavor', '', 'string')
        # for each network, create a parameter
        networks_id.each do |net|
            hot.parameters_list << Parameter.new(net['heat'], '', 'string')
        end
        router_interfaces.each do |iface|
            hot.parameters_list << Parameter.new(iface, '', 'string')
        end

        arr = []
        router_interfaces.each do |iface|
            arr << { 'get_param' => iface }
        end

        ports = []
        connection_points = vdu['connection_points']
        vlinks = vnfd['vlinks']
        vdu_id = vdu['id']
        auto_scale_name = get_resource_name
        connection_points.each do |connection_point|
            vlink = vlinks.find { |vlink| vlink['id'] == connection_point['vlink_ref'] }
            # detect, and return error if not.
            network = networks_id.detect { |network| network['alias'] == vlink['alias'] }
            next if network.nil?
            port_name = (connection_point['id']).to_s
            ports << { 'port' => { 'get_resource' => port_name } }
            if vlink['existing_net_id']
                if vlink['port_security_enabled']
                    hot.resources_list << Port.new(port_name, network['heat_id'], security_group_id)
                else
                    hot.resources_list << Port.new(port_name, network['heat_id'])
                end
            else
                if vlink['port_security_enabled']
                    hot.resources_list << Port.new(port_name, { 'get_param' => network['heat'] }, security_group_id)
                else
                    hot.resources_list << Port.new(port_name, 'get_param' => network['heat'])
                end
            end
            # router_interface_name = get_resource_name_nested(hot)
            # hot.resources_list << RouterInterface.new(router_interface_name, router_id, nil, {"get_resource" => port_name})

            # Check if it's necessary to create an output for this resource
            if outputs_list.key?('ip') && outputs_list['ip'].include?(port_name)
                hot.outputs_list << Output.new("#{port_name}#ip", "#{port_name} IP address", 'get_attr' => [port_name, 'fixed_ips', 0, 'ip_address'])
            end

            # Check if the port has a Floating IP
            if vlink['access']
                floating_ip_name = get_resource_name_nested(hot)
                # TODO: Receive the floating ip pool name?
                hot.resources_list << FloatingIp.new(floating_ip_name, @public_network_id)
                hot.resources_list << FloatingIpAssociation.new(get_resource_name_nested(hot), { 'get_resource' => floating_ip_name }, { 'get_resource' => port_name }, [])
                hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#PublicIp", "#{port_name} Floating IP", 'get_attr' => [floating_ip_name, 'floating_ip_address'])
                @hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#PublicIp", "#{port_name} Nested outputs_list", 'get_attr' => [auto_scale_name, 'outputs_list', "#{vdu_id}##{connection_point['id']}#PublicIp"])
            else
                hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#PrivateIp", "#{port_name} Private IP", 'get_attr' => [port_name, 'fixed_ips', 0, 'ip_address'])
                @hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#fixed_ips#0#ip_address", "#{port_name} Nested outputs_list", 'get_attr' => [auto_scale_name, 'outputs_list', "#{vdu_id}##{connection_point['id']}#PrivateIp"])
            end
        end

        hot.resources_list << Server.new(
            vdu['id'],
            { 'get_param' => 'flavor' },
            { 'get_param' => 'image' },
            ports,
            add_wait_condition2(vdu, hot),
            nil
        )
        hot.outputs_list << Output.new("#{vdu['id']}#id", "#{vdu['id']} ID", 'get_resource' => vdu['id'])
        @hot.outputs_list << Output.new("#{vdu['id']}#vdus", "#{vdu['id']} ID", 'get_attr' => [auto_scale_name, 'outputs_list', "#{vdu['id']}#id"])
        hot
    end

    def create_networks(vlink, dns_server, router_id)
        network_name = create_network(vlink['id'], vlink['alias'], vlink['port_security_enabled'])
        cidr = if vlink['net_segment'] && vlink['net_segment'] != ''
                   vlink['net_segment']
               else
                   '192.' + rand(256).to_s + '.' + rand(256).to_s + '.0/24'
               end
        subnet_name = create_subnet(vlink['id'], dns_server, cidr)
        if vlink['connectivity_type'] == 'E-LAN'
        # create_router_interface(router_id, subnet_name)
        elsif vlink['connectivity_type'] == 'E-LINE'
            # nothig to do
        end

        router_interface = create_router_interface(router_id, subnet_name, nil)

        [network_name, router_interface]
    end

    def create_network(resource_name, network_name, port_security_enabled)
        name = get_resource_name
        @hot.resources_list << Network.new(resource_name, network_name, port_security_enabled)
        name
    end

    def create_subnet(network_name, dns_server, cidr)
        name = get_resource_name
        @hot.resources_list << Subnet.new(name, { get_resource: network_name }, dns_server, cidr)
        name
    end

    def create_router_interface(router_id, subnet_name, port_name)
        name = get_resource_name
        @hot.resources_list << RouterInterface.new(name, router_id, { get_resource: subnet_name }, get_resource: port_name)
        name
    end

    # Parse the outputs from the VNFD and builds an outputs hash
    #
    # @param [Hash] events the VNF lifecycle events
    def parse_outputs(events)
        outputs = []

        events.each do |_event, event_info|
            next if event_info.nil? || event_info['template_file'].nil?
            raise CustomException::InvalidTemplateFileFormat, 'Template file format not supported' unless event_info['template_file_format'].casecmp('json').zero?
            JSON.parse(event_info['template_file']).each do |_id, output|
                next if outputs.include?(output)
                outputs << output

                match = output.delete(' ').match(/^get_attr\[(.*)\]$/i).to_a
                if match.empty?
                    puts output
                    puts 'The match is null.'
                else
                    string = match[1].split(',').map(&:strip)
                    if string.empty?
                        puts "Error getting the 'get_attr' of " + match[1]
                    else
                        get_attr = { get_attr: [] }
                        string.each_with_index do |type, _i|
                            get_attr[:get_attr] << if CommonMethods.is_num?(type)
                                                       type.to_i
                                                   else
                                                       type
                                                   end
                        end

                        if @outputs.key?(match[2])
                            @outputs[match[2]] << match[1]
                        else
                            @outputs[match[2]] = [match[1]]
                        end
                        if string[1] == 'fixed_ips'
                            # @hot.outputs_list << Output.new(id, "", get_attr)
                        end
                        if string[1] != 'PublicIp'
                            # @hot.outputs_list << Output.new(id, "", get_attr)
                        end
                    end
                end
            end
        end
    end

    # Creates an HEAT key pair resource
    #
    # @param [Hash] keypair_name the Name of the KeyPair
    # @return [String] the name of the created resource
    def create_key_pair(keypair_name)
        name = get_resource_name

        @hot.resources_list << KeyPair.new(name, keypair_name)
        @hot.outputs_list << Output.new('private_key', 'Private key', get_attr: [name, 'private_key'])
        name
    end

    # Creates an HEAT image resource from the VNFD
    #
    # @param [Hash] vdu the VDU from the VNFD
    # @return [String] the name of the created resource
    def create_image(vdu)
        name = get_resource_name

        raise CustomException::NoExtensionError, "#{vdu['vm_image']} does not have a file extension" if vdu['vm_image_format'].empty?
        raise CustomException::InvalidExtensionError, "#{vdu['vm_image']} has an invalid extension. Allowed extensions: ami, ari, aki, vhd, vmdk, raw, qcow2, vdi and iso" unless %w(ami ari aki vhd vmdk raw qcow2 vdi iso).include? vdu['vm_image_format']

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
    def create_ports(vdu_id, connection_points, vlinks, networks_id, security_group_id, router_interfaces)
        ports = []

        connection_points.each do |connection_point|
            vlink = vlinks.find { |vlink| vlink['id'] == connection_point['vlink_ref'] }
            # detect, and return error if not.
            network = networks_id.detect { |network| network['alias'] == vlink['alias'] }
            next if network.nil?
            port_name = (connection_point['id']).to_s
            ports << { port: { get_resource: port_name } }
            if vlink['existing_net_id']
                if vlink['port_security_enabled']
                    @hot.resources_list << Port.new(port_name, network['heat_id'], security_group_id)
                else
                    @hot.resources_list << Port.new(port_name, network['heat_id'])
                end
            else
                if vlink['port_security_enabled']
                    @hot.resources_list << Port.new(port_name, { get_resource: network['heat'] }, security_group_id)
                else
                    @hot.resources_list << Port.new(port_name, get_resource: network['heat'])
                end
            end

            # Check if it's necessary to create an output for this resource
            if @outputs.key?('ip') && @outputs['ip'].include?(port_name)
                @hot.outputs_list << Output.new("#{port_name}#ip", "#{port_name} IP address", get_attr: [port_name, 'fixed_ips', 0, 'ip_address'])
            end

            # Check if the port has a Floating IP
            if vlink['access']
                floating_ip_name = get_resource_name
                # TODO: Receive the floating ip pool name?
                @hot.resources_list << FloatingIp.new(floating_ip_name, @public_network_id)
                @hot.resources_list << FloatingIpAssociation.new(get_resource_name, { get_resource: floating_ip_name }, { get_resource: port_name }, router_interfaces)
                #          @hot.outputs_list << Output.new("#{port_name}#floating_ip", "#{port_name} Floating IP", {get_attr: [floating_ip_name, 'floating_ip_address']})
                @hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#PublicIp", "#{port_name} Floating IP", get_attr: [floating_ip_name, 'floating_ip_address'])
                @hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#fixed_ips#0#ip_address", "#{port_name} private address", 'get_attr' => [port_name, 'fixed_ips', 0, 'ip_address'])
            else
                @hot.outputs_list << Output.new("#{vdu_id}##{connection_point['id']}#fixed_ips#0#ip_address", "#{port_name} private address", 'get_attr' => [port_name, 'fixed_ips', 0, 'ip_address'])
            end
        end

        ports
    end

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
            vdu['resource_requirements']['vcpus']
        )
        name
    end

    # Creates an HEAT server resource from the VNFD
    #
    # @param [Hash] vdu the VDU from the VNFD
    # @param [String] image_name the image resource name
    # @param [String] flavour_name the flavour resource name
    # @param [Array] ports list of the ports resource
    def create_server(vdu, image, flavour_name, ports, key_name, scale)
        if scale
            server = Server.new(
                vdu['id'],
                flavour_name,
                image,
                ports,
                add_wait_condition(vdu),
                get_resource: key_name
            )
        else
            @hot.resources_list << Server.new(
                vdu['id'],
                flavour_name,
                image,
                ports,
                add_wait_condition(vdu),
                get_resource: key_name
            )
            @hot.outputs_list << Output.new("#{vdu['id']}#id", "#{vdu['id']} ID", get_resource: vdu['id'])
        end

        server
    end

    # Adds a Wait Condition resource to the VDU
    #
    # @param [Hash] vdu the VDU from the VNFD
    # @return [Hash] the user_data script with the Wait Condition
    def add_wait_condition(vdu)
        wc_handle_name = get_resource_name

        if vdu['wc_notify']
            if @type != 'vSA'
                @hot.resources_list << WaitConditionHandle.new(wc_handle_name)
                @hot.resources_list << WaitCondition.new(get_resource_name, wc_handle_name, 2000)
            end
        else
            bootstrap_script = vdu.key?('bootstrap_script') ? vdu['bootstrap_script'] : ""
            return bootstrap_script
        end

        wc_notify = ''
        wc_notify = "\nwc_notify --data-binary '{\"status\": \"SUCCESS\"}'\n"
        if vdu['wc_notify']
            wc_notify = "\nwc_notify --data-binary '{\"status\": \"SUCCESS\"}'\n"
        end
        if @type == 'vSBC'
            wc_notify = ''
        elsif @type == 'vSA'
            wc_notify = '\n echo "tenor_url: http://10.10.1.61:4000/vnf-provisioning/' + @vnfr_id + '/stack/create_complete" > /etc/tenor.cfg'
            wc_notify = '\n echo curl -XPOST http://10.10.1.61:4000/vnf-provisioning/' + @vnfr_id + '/stack/create_complete -d "info" '
            wc_notify = ''
            wc_notify += "\nwc_notify --data-binary '{\"status\": \"SUCCESS\"}'\n"
        end

        # if vdu['wc_notify']
        shell = '#!/bin/bash'
        shell = '#!/bin/tcsh' if @type == 'vSA'
        if @type != 'vSA'
            bootstrap_script = vdu.key?('bootstrap_script') ? vdu['bootstrap_script'] : shell
            {
                str_replace: {
                    params: {
                        wc_notify: {
                            get_attr: [wc_handle_name, 'curl_cli']
                        }
                    },
                    template: bootstrap_script + wc_notify
                }
            }
        else
            bootstrap_script = '#!/bin/bash' + wc_notify
        end
        # end
    end

    def add_wait_condition2(vdu, hot)
        wc_handle_name = get_resource_name_nested(hot)

        # if vdu['wc_notify']
        if @type != 'vSA' && !vdu['wc_notify'].nil?
            hot.resources_list << WaitConditionHandle.new(wc_handle_name)
            hot.resources_list << WaitCondition.new(get_resource_name_nested(hot), wc_handle_name, 2000)
            # end
        end

        wc_notify = ''
        wc_notify = "\nwc_notify --data-binary '{\"status\": \"SUCCESS\"}'\n"
        if vdu['wc_notify']
            wc_notify = "\nwc_notify --data-binary '{\"status\": \"SUCCESS\"}'\n"
        end

        shell = '#!/bin/bash'
        shell = '#!/bin/tcsh' if @type == 'vSA'

        bootstrap_script = vdu.key?('bootstrap_script') ? vdu['bootstrap_script'] : shell
        {
            'str_replace' => {
                'params' => {
                    'wc_notify' => {
                        'get_attr' => [wc_handle_name, 'curl_cli']
                    }
                },
                'template' => bootstrap_script + wc_notify
            }
        }
    end

    # Generates a new resource name
    #
    # @return [String] the generated resource name
    def get_resource_name
        @name + '_' + @hot.resources_list.length.to_s unless @name.empty?
    end

    def get_resource_name_nested(hot)
        @name + '_nested_' + hot.resources_list.length.to_s unless @name.empty?
    end

    # Converts a value to another unit
    #
    # @param [Numeric] value the value to convert
    # @param [String] input_unit the unit to convert from
    # @param [String] output_unit the unit to convert to
    # @return [Numeric] the converted value
    def unit_converter(value, input_unit, output_unit)
        return 0 if value == 0
        return value if input_unit.casecmp(output_unit.downcase).zero?

        if input_unit.casecmp('gb').zero?
            return value * 1024 if output_unit.casecmp('mb').zero?
        else
            if input_unit.casecmp('mb').zero?
                return value / 1024 if output_unit.casecmp('gb').zero?
            else
                if input_unit.casecmp('tb').zero?
                    return value * 1024 if output_unit.casecmp('gb').zero?
                end
            end
        end
    end

    def create_autoscale_group(cooldown, max_size, min_size, desired_capacity, resource)
        name = get_resource_name
        @hot.resources_list << AutoScalingGroup.new(name, cooldown, max_size, min_size, desired_capacity, resource)
        name
    end

    def create_scale_policy(auto_scaling_group, scaling_adjustment)
        name = get_resource_name
        @hot.resources_list << ScalingPolicy.new(name, { get_resource: auto_scaling_group }, scaling_adjustment)
        name
    end
end
