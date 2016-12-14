FactoryGirl.define do
	factory :nsr do
		sequence(:_id) { |n| n.to_s }
		service_deployment_flavour "gold"
		resource_reservation []
		vnfrs []
		lifecycle_event_history []
	end

	factory :nsr_example, class: Nsr do
		sequence(:_id) { |n| n.to_s }
		service_deployment_flavour "gold2"
                notification "http://markeplace_url"
                authentication [
                        {
                            "pop_id" => "3",
                            "is_admin" => false,
                            "urls" => {
                                "dns" => [
                                    "10.30.0.11"
                                ],
                                "keystone" => "http://vimurl:35357/v2.0",
                                "orch" => "http://vimurl:8004/v1",
                                "compute" => "http://vimurl:8774/v2.1",
                                "neutron" => "http://vimurl:9696/v2.0",
                                "netfloc_ip" => "netfloc_ip",
                                "netfloc_user" => "netfloc_user",
                                "netfloc_pass" => "netfloc_pass"
                            },
                            "username" => "tenor_user",
                            "tenant_name" => "tenor_tenant",
                            "password" => "secretsecret",
                            "tenant_id" => "16b6c1cdb8604e3a84569e40edfce83a",
                            "user_id" => "65c2f2d244a64855938f061fa7027d79",
                            "token" => "eeebc59ad28d44e1bf70e91d7495ad5f"
                        }
                ]
		vnfrs [{
            "vnfd_id" => "29366",
            "vnfi_id" => [],
            "vnfr_id"=> "582db32fc098a44336000004",
            "pop_id"=> "3",
            "status"=> ""
                }
            ]
		lifecycle_event_history []
		resource_reservation [{
            "ports"=> [
                {
                    "ns_network"=> "VNF#29366:ext_management",
                    "vnf_ports"=> [
                        {
                            "id"=> "CPfs0h",
                            "vlink_ref"=> "vl0",
                            "physical_resource_id"=> "caec5bc1-7275-4d1f-bebe-5ddf889b97c3"
                        }
                    ]
                },
                {
                    "ns_network"=> "VNF#29366:ext_data",
                    "vnf_ports"=> [
                        {
                            "id"=> "CPng8r",
                            "vlink_ref"=> "vl1",
                            "physical_resource_id"=> "08fb386a-063f-4951-9e7b-3273e990542a"
                        }
                    ]
                },
                {
                    "ns_network"=> "VNF#29366:ext_data2",
                    "vnf_ports"=> [
                        {
                            "id"=> "CPng8q",
                            "vlink_ref"=> "vl1",
                            "physical_resource_id"=> "08fb386a-063f2-4951-9e7b-3273e990542a"
                        }
                    ]
                }
            ],
            "network_stack"=> {
                "id"=> "e7bcdeb8-a5ca-4316-b245-6f48c9c27249",
                "stack_url"=> "http://vimurl:8004/v1/16b6c1cdb8604e3a84569e40edfce83a/stacks/network_582db31dc098a445c3000000/e7bcdeb8-a5ca-4316-b245-6f48c9c27249"
            },
            "public_network_id": "121ad8e8-a656-4baf-a306-9b88db8de2a8",
            "dns_server"=> [
                "10.30.0.11"
            ],
            "pop_id"=> "3",
            "routers"=> [
                {
                    "id"=> "1990098f-1a3f-4234-b017-7ac4e4e8cf3d",
                    "alias"=> "1990098f-1a3f-4234-b017-7ac4e4e8cf3d"
                }
            ],
            "networks"=> [
                {
                    "id"=> "7d7aecc1-8ae1-4765-96de-6a90caf6fcb8",
                    "alias"=> "7d7aecc1-8ae1-4765-96de-6a90caf6fcb8"
                },
                {
                    "id"=> "2ec10a93-74e7-42fe-a2ce-1299c3ebad78",
                    "alias"=> "2ec10a93-74e7-42fe-a2ce-1299c3ebad78"
                }
            ]
        }]
        vnffgd {{ "vnffgs" => [{
                  "vnffg_id"=>"vnffg0",
                  "number_of_endpo ints"=>1,
                  "number_of_virtual_links"=>1,
                  "dependent_virtual_links"=>[
                    "vld1"
                  ],
                  "network_forwarding_path"=>[
                    {
                      "nfp_id"=>"nfp0",
                      "graph"=>[
                        "vld1"
                      ],
                      "connection_points"=>[
                        "ns_ext_data_in",
                        "VNF#29366:ext_data"
                      ],
                      "constituent_vnfs"=>[
                        {
                          "vnf_ref_id"=>"29366",
                          "vnf_flavor_key_ref"=>"gold"
                        }
                      ]
                    }
                  ]
                  },
                  {
                        "vnffg_id"=> "vnffg1",
                        "number_of_endpoints"=> 2,
                        "number_of_virtual_links"=> 3,
                        "dependent_virtual_links"=> [
                            "vld0",
                            "vld1",
                            "vld2"
                        ],
                        "network_forwarding_path"=> [
                            {
                                "nfp_id"=> "nfp0",
                                "graph"=> [
                                    "vld0",
                                    "vld1",
                                    "vld2"
                                ],
                                "connection_points"=> [
                                    "ns_ext_in",
                                    "VNF#29366:ext_data2"
                                ],
                                "constituent_vnfs"=> [
                                    {
                                        "vnf_ref_id"=> "29366",
                                        "vnf_flavor_key_ref"=> "gold"
                                    }
                                ]
                            }
                        ]
                    }
              ]
          }}
	end

            factory :nsr_example_netfloc, class: Nsr do
		sequence(:_id) { |n| n.to_s }
		service_deployment_flavour "basic"
                notification "http://markeplace_url"
                authentication [
                        {
                            "pop_id" => "3",
                            "is_admin" => false,
                            "urls" => {
                                "dns" => [
                                    "10.30.0.11"
                                ],
                                "keystone" => "http://vimurl:35357/v2.0",
                                "orch" => "http://vimurl:8004/v1",
                                "compute" => "http://vimurl:8774/v2.1",
                                "neutron" => "http://vimurl:9696/v2.0"
                            },
                            "username" => "tenor_user",
                            "tenant_name" => "tenor_tenant",
                            "password" => "secretsecret",
                            "tenant_id" => "16b6c1cdb8604e3a84569e40edfce83a",
                            "user_id" => "65c2f2d244a64855938f061fa7027d79",
                            "token" => "eeebc59ad28d44e1bf70e91d7495ad5f"
                        }
                ]
		vnfrs [{
            "vnfd_id" => "2251",
            "vnfi_id" => [
               "aef3dbdb-eb97-437a-9852-78ce3fd7b29d"
            ],
            "vnfr_id"=> "5832f69cc098a4433d000027",
            "pop_id"=> "3",
            "status"=> "INSTANTIATED"
                }, {
   "vnfd_id" => "29366",
   "vnfi_id" => [],
   "vnfr_id"=> "5832f69dc098a4433d000028",
   "pop_id"=> "3",
   "status"=> ""
       }
            ]
		lifecycle_event_history []
		resource_reservation [{
            "ports"=> [
                                {
                            "ns_network": "VNF#2251:ext_traffic-in",
                            "vnf_ports": [
                                {
                                    "id": "CPdx0g",
                                    "vlink_ref": "vl1",
                                    "physical_resource_id": "626bd4bf-4c53-4719-aa7e-3c6eb2cf75a2"
                                }
                            ]
                        },
                        {
                            "ns_network": "VNF#2251:ext_traffic-out",
                            "vnf_ports": [
                                {
                                    "id": "CPtjag",
                                    "vlink_ref": "vl2",
                                    "physical_resource_id": "0167c63d-3db0-4fe6-90af-594e877d3af1"
                                }
                            ]

                }],
            "network_stack"=> {
                "id"=> "e7bcdeb8-a5ca-4316-b245-6f48c9c27249",
                "stack_url"=> "http://vimurl:8004/v1/16b6c1cdb8604e3a84569e40edfce83a/stacks/network_582db31dc098a445c3000000/e7bcdeb8-a5ca-4316-b245-6f48c9c27249"
            },
            "public_network_id": "121ad8e8-a656-4baf-a306-9b88db8de2a8",
            "dns_server"=> [
                "10.30.0.11"
            ],
            "pop_id"=> "3",
            "routers"=> [
                {
                    "id"=> "1990098f-1a3f-4234-b017-7ac4e4e8cf3d",
                    "alias"=> "1990098f-1a3f-4234-b017-7ac4e4e8cf3d"
                }
            ],
            "networks"=> [
                {
                    "id"=> "a4abca8b-d5d8-44b5-af29-ea2daa2f62a8",
                    "alias"=> "a4abca8b-d5d8-44b5-af29-ea2daa2f62a8"
                },
                {
                    "id"=> "a0b98f37-490a-4df8-977a-6ae1151706f2",
                    "alias"=> "a0b98f37-490a-4df8-977a-6ae1151706f2"
                },
                {
                    "id"=> "6f847f18-8080-4c07-883d-b473a135363d",
                    "alias"=> "6f847f18-8080-4c07-883d-b473a135363d"
                }
            ]
        }]
        vnffgd {{ "vnffgs" => [{
                  "vnffg_id"=>"vnffg0",
                  "number_of_endpo ints"=>1,
                  "number_of_virtual_links"=>1,
                  "dependent_virtual_links"=>[
                    "vld0",
                    "vld1",
                    "vld2"
                  ],
                  "network_forwarding_path"=>[
                    {
                      "nfp_id"=>"nfp0",
                      "graph"=>[
                        "vld0",
                            "vld1",
                            "vld2"
                      ],
                      "connection_points"=>[
                            "ns_ext_in",
                            "VNF#2251:ext_traffic-in",
                            "VNF#2251:ext_traffic-out",
                            "VNF#29366:ext_vtu-mng",
                            "VNF#29366:ext_vtu-data",
                            "ns_ext_out"
                      ],
                      "constituent_vnfs"=>[
                            {
                                "vnf_ref_id"=> "2251",
                                "vnf_flavor_key_ref"=> "gold"
                            },
                            {
                                "vnf_ref_id"=> "29366",
                                "vnf_flavor_key_ref"=> "gold"
                            }
                      ]
                    }
                  ]
                  },
                  {
                        "vnffg_id"=> "vnffg1",
                        "number_of_endpoints"=> 2,
                        "number_of_virtual_links"=> 3,
                        "dependent_virtual_links"=> [
                            "vld0",
                            "vld1",
                            "vld2"
                        ],
                        "network_forwarding_path"=> [
                            {
                                "nfp_id"=> "nfp0",
                                "graph"=> [
                                    "vld0",
                                    "vld1",
                                    "vld2"
                                ],
                                "connection_points"=> [
                                    "ns_ext_in",
                                   "VNF#2251:ext_traffic-in",
                                   "VNF#2251:ext_traffic-out",
                                  "ns_ext_out"
                                ],
                                "constituent_vnfs"=> [
                            {
                                "vnf_ref_id"=> "2251",
                                "vnf_flavor_key_ref"=> "gold"
                            }
                                ]
                            }
                        ]
                    }
              ]
          }}
	end
end
