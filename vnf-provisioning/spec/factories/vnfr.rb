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
        "authentication"=> "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAz3mj9mVO2pz5JYOnvVXwHTia+56LZXoXXvwSRhujExv+2w1D\n3K8ldlucegfhMGqxRqPICQo7Teczal1LyGk9C1BlGWdqr1MRaFw/z3JrjCw2ajjn\nAjZzf0KwDA3/ayiQoUt/07rAah0WapEVJQWuOJWyyYijHUDrguS2Ccj3eYAx+UsF\nGTfX6GoIFavMiK0W9eIBZy4BT3jPzL87LFtll5jz7C6E0GiuYI1+Dfqy7M08/PhL\nlUpAEN/Yj15YFDvXG5kS8fFGByBbJfWMG8gHFi9UIiTmxeTJYkOQSDyIdTHgusmG\nSpmPA8+xPAedB0KwKkKNwYUXBGBh3P0t/NBX+QIDAQABAoIBAHpMAolQKE4W74nc\ndDjX+mTPJBQj3ZlggXw86+ylh9fQzcaDqDfiihudXrxT/rqSeZLhIh2qCVEfcqBF\nBFHLLu+HYUC7RBi6x20Ty41Vre1/dkfg6NLWE/i07577dU7OJ4rcPSoqUBd8s+T3\nRlZ/ZbX3D99aCoRI60pJ1MAp1S6pgWNuepi2tgQfs648j6hHRNLrKTzlnf09V0L2\nz228qIDt1Tencr1L2YXTB6tt1uErxp7gAxDyPPT/meJSvnImrVPKEvgKJ3nzRjCD\nkq+ctmdrwkROgxVqHCKZ1UPdP5OZ2JPVehWPNObCK/iaKGsRimuGynJq3g+0AFT+\nwOkmOoECgYEA76YZam2gd3Byc8ObqqTKzTxrMPqBNYtrrxDHpJGuoQWUhPT9KawC\n31AzSpM62+tkRoS145UOAkdWgjRep7ghoPDdbNzx1B6iw7dBUpLQFZrjPN4epf5r\nV4vbCuISMqBaeQlIc4SBHkgxg7b7MMMOOWbzqN7UTmPTYwbzG93Wt7ECgYEA3aGR\n4NBO8pqdKG/Gp7TNDhawqJIOx9ZK7RU6zSVR/FZwrLewu9r9G0foZU9cPl0ZyYCq\nJIHY0D6g3P4iHCwCyF1F4Pr0JJDplLroPLinAN/zXd+1mHxD+drE2Ln8AR87Keui\nVyYfXnMj2v9l+IO6z/4L+F3vChHV5YxZRmMhfskCgYAiacSujs2DOUeGLim1aHKi\n5DE0WFSjnsC44/z3OeBMySNZsGCGUmgbL0YeSGQkXnoI0lfYNXhMhXf7vI93IC7c\nEJqLXnLvlfKjjjY4KFLvN024WOEnzxAVA0VSG8KnOHWledrIk9eCxLUvh+AsUWZC\ngfEtZ8ou85DQYJgagVGrEQKBgD8l1vu4PpZPSXIJDxAfqsFV47XUD9QOkcClaOCk\nvoxoUKhVmkycI7vPLD8Zco3uVveb6l6GhLEo9wqgejWOsKhIMy3cMw3sIDGZY6xR\nbHwKUzwvDn3JAlFBbQ7XRx9Gt8PE+LdeDFgL9G5kkLhTSDoVB3IXyZET7d7+sz0j\n55pJAoGBAKdl5z7p2lbD5D3Du6BtX72/uyK4yl2PvtzU8q0Q8YgRD2allE/RKuqk\naTHowishnwRe7M+4hpVwOggxAETDxDHDkP30kXertclrOhc051XA8bT3tWY90/rI\nhIxit0+O62NfAgIdk1dgmkrdZDd0hzOKG7Xp57Wxxlbe1AaUmljT\n-----END RSA PRIVATE KEY-----",
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
