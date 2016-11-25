FactoryGirl.define do
	factory :vnfr do
		sequence(:_id) { |n| n.to_s }
		#sequence(:lifecycle_info) { |n| {authentication_username: 'test_' + n.to_s, driver: "ssh"} }
		scale_resources []
		stack_url "http://localhost/stackurl"
		deployment_flavour "gold"
        lifecycle_info {{
        "authentication_username"=> "italtel",
        "driver"=> "ssh",
        "authentication_type"=> "PubKeyAuthentication",
        "authentication"=> "",
        "authentication_port"=> 22,
        "flavor_id_ref"=> "flavor0",
        "events"=> {
            "start"=> {
                "command"=> "/vTU/bin/vTUstart",
                "template_file"=> "{\"controller\":\"get_attr[vdu0,PublicIp]\", \"vdu0\":\"get_attr[vdu1,PublicIp]\"}",
                "template_file_format"=> "JSON"
            },
            "stop"=> {
                "command"=> "/vTU/bin/vTUstop",
                "template_file"=> "{}",
                "template_file_format"=> "JSON"
            },
            "restart"=> {
                "command"=> "/vTU/bin/vTUrestart",
                "template_file"=> "{\"controller\":\"get_attr[vdu0,PublicIp]\", \"vdu0\":\"get_attr[vdu1,PublicIp]\"}",
                "template_file_format"=> "JSON"
            }
        },
        "vnf_container"=> "/vTU"
    }}
		port_instances [{
            "id"=> "CPnfwb",
            "vlink_ref"=> "vl0",
            "physical_resource_id"=> "944da4e4-2c5d-488f-a0d7-2b296d71f914"
        },
        {
            "id"=> "CPl5k3",
            "vlink_ref"=> "vl1",
            "physical_resource_id"=> "623c2680-ef76-4fa9-8238-2f737e436984"
        }]
        vlr_instances [
        {
            "id"=> "vl0",
            "alias"=> "vTU-mngt",
            "physical_resource_id"=> "b37b3178-6312-4559-b6c6-dd0ede5d4c39"
        },
        {
            "id"=> "vl1",
            "alias"=> "vTU-data",
            "physical_resource_id"=> "f38f3fa6-5ff3-4bbd-b2c3-83e6871552c0"
        }
    ]
	end
end
