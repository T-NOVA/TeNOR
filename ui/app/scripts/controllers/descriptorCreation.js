'use strict';

angular.module('tNovaApp')
    .controller('descriptionCreationController', function ($scope, $filter, $alert) {

        //load NSD schema in tv4
        $.getJSON('../../schemas/nsd_schema.json', function (response) {
            var jsonSchema = response;
            tv4.addSchema("nsd_schema", jsonSchema);
        });

        $scope.selectedIcons = [];
        $scope.nsds = [];

        //$scope.multiplePanels.activePanels = [2];

        $scope.flavours

        $scope.getFlavours = function (vnfd) {
            //console.log($scope.nsd.sla[0].constituent_vnfs);
            if (vnfd == undefined) return;
            return $scope.vnfs.filter(function (d) {
                return d.vnfd.id === $scope.nsd.sla[0].constituent_vnfs;
            })[0].vnfd.deployment_flavours;
        };

        $scope.getEvents = function (index, type) {
            console.log(index);
            console.log(type);
            console.log($scope.nsd.lifecycle_events[type][index]);
            console.log($scope.vnfs.filter(function (d) {
                return d.vnfd.id === $scope.nsd.lifecycle_events[type][index].vnf_id.vnfd.id;
            })[0]);
            return $scope.vnfs.filter(function (d) {
                return d.vnfd.id === $scope.nsd.lifecycle_events[type][index].vnf_id.vnfd.id;
            })[0].vnfd.vdu.vnf_lifecycle_events;
        };

        $scope.addNSD = function (nsd) {
            $scope.nsds.push(nsd)
        };

        $scope.addSla = function () {
            var newItemNo = $scope.nsd.sla.length + 1;
            $scope.nsd.sla.push({
                'id': 'sla' + newItemNo
            });
        };
        $scope.addConstituentVnf = function (sla_index) {
            var newItemNo = $scope.nsd.sla[sla_index].constituent_vnfs.length + 1;
            $scope.nsd.sla[sla_index].constituent_vnfs.push({
                'id': 'sla' + newItemNo
            });
        };

        $scope.addNew = function (type) {
            var newItemNo = $scope.nsd["'" + type + "'"].length + 1;
            $scope.nsd["'" + type + "'"].push({
                'id': type + newItemNo
            });
        };

        $scope.addStart = function () {
            var newItemNo = $scope.nsd.lifecycle_events.start.length + 1;
            $scope.nsd.lifecycle_events.start.push({
                'id': "start" + newItemNo
            });
        };

        $scope.showAddChoice = function (choice) {
            return choice.id === $scope.choices[$scope.choices.length - 1].id;
        };


        $scope.removeItems = function (type) {
            $scope.nsd[type].pop();
        };

        $scope.removeSlas = function () {
            var newItemNo = $scope.choices.length - 1;
            if (newItemNo !== 0) {
                $scope.nsd.sla.pop();
            }
        };

        $scope.submitNsd = function () {

            $scope.registerForm = {};
            //$scope.registerForm.sla = [];

            var nsd = {
                "nsd": $scope.nsd
            };
            console.log(nsd);
            var jsData;

            var valid = tv4.validate(jsData != null ? jsData : {
                "nsd": $scope.nsd
            }, tv4.getSchema("nsd_schema"));
            console.log(valid);

            if (valid) {
                $alert({
                    title: "NSD created",
                    content: "",
                    placement: 'top',
                    type: 'danger',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
                return
            }

            console.log(tv4.error);
            $alert({
                title: "Error with the creation of the NSD: ",
                content: tv4.error.message,
                placement: 'top',
                type: 'danger',
                keyboard: true,
                show: true,
                container: '#alerts-container',
                duration: 5
            });
            console.log(tv4.error.dataPath);
            if (tv4.error.dataPath == "/nsd") {
                $scope.registerForm.information = true;
            }
            if (tv4.error.dataPath == "/nsd/vnfds") {
                $scope.registerForm.vnfds = true;
            }
            if (tv4.error.dataPath.indexOf("/nsd/sla") > -1) {
                $scope.registerForm.sla = true;
                var res = tv4.error.dataPath(/\/nsd\/(.*)\/(.*)/);
                console.log(res);
                $scope.registerForm.sla[res[1]].sla_key = true;
            }
        };

        $scope.nsd = {
            "version": "1.0",
            "id": Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 20),
            "vnfds": [],
            "lifecycle_events": {
                "start": [],
                "stop": [],
                "scale_out": []
            },
            "vnf_depedency": [],
            "monitoring_parameters": [],
            "vld": {},
            "sla": []
        }

        /* $scope.nsd.vnfds.push({
             "name": "vnf1",
             "version": "aaa",
             "vnfd": {
                 "id": 1618
             }
         });*/

        $scope.nsd2 = {
            vnfds: {
                "id": "1",
                "type": "item"
            },
            A: {
                "type": "container",
                "id": 1,
                "columns": [
                        [
                        {
                            "type": "item",
                            "id": "1"
                            },
                        {
                            "type": "item",
                            "id": "2"
                            }
                        ],
                        [
                        {
                            "type": "item",
                            "id": "3"
                            }
                        ]
                    ]
            }
        }

        $scope.models = {
            selected: null,
            templates: [
                {
                    type: "item",
                    id: 2
            },
                {
                    type: "container",
                    id: 1,
                    columns: [[], []]
            },
                {
                    type: "vnfd",
                    id: 1,
                    columns: [[], []]
            },
                {
                    type: "sla",
                    id: 3,
                    columns: [[], []]
            },
                {
                    type: "lifecycle",
                    id: 3,
                    columns: [[], []]
            }
        ],
            dropzones: {
                "A": [
                    {
                        "type": "container",
                        "id": 1,
                        "columns": [
                        [
                                {
                                    "type": "item",
                                    "id": "1"
                            },
                                {
                                    "type": "item",
                                    "id": "2"
                            }
                        ],
                        [
                                {
                                    "type": "item",
                                    "id": "3"
                            }
                        ]
                    ]
                },
                    {
                        "type": "item",
                        "id": "4"
                },
                    {
                        "type": "item",
                        "id": "5"
                },
                    {
                        "type": "item",
                        "id": "6"
                }
            ],
                "B": [
                    {
                        "type": "item",
                        "id": 7
                },
                    {
                        "type": "item",
                        "id": "8"
                },
                    {
                        "type": "container",
                        "id": "2",
                        "columns": [
                        [
                                {
                                    "type": "item",
                                    "id": "9"
                            },
                                {
                                    "type": "item",
                                    "id": "10"
                            },
                                {
                                    "type": "item",
                                    "id": "11"
                            }
                        ],
                        [
                                {
                                    "type": "item",
                                    "id": "12"
                            },
                                {
                                    "type": "container",
                                    "id": "3",
                                    "columns": [
                                    [
                                            {
                                                "type": "item",
                                                "id": "13"
                                        }
                                    ],
                                    [
                                            {
                                                "type": "item",
                                                "id": "14"
                                        }
                                    ]
                                ]
                            },
                                {
                                    "type": "item",
                                    "id": "15"
                            },
                                {
                                    "type": "item",
                                    "id": "16"
                            }
                        ]
                    ]
                },
                    {
                        "type": "item",
                        "id": 16
                }
            ]
            }
        };

        $scope.$watch('nsd', function (model) {
            $scope.modelAsJson = angular.toJson(model, true);
        }, true);


        $scope.vnfs = [
            {
                "name": "TEMP",
                "version": 1,
                "vnf-manager": "TEMP",
                "vnfd": {
                    "vdu": [
                        {
                            "resource_requirements": {
                                "network_interface_bandwidth_unit": "",
                                "hypervisor_parameters": {
                                    "version": "10002|12001|2.6.32-358.el6.x86_64",
                                    "type": "QEMU-KVM"
                                },
                                "memory_unit": "GB",
                                "network_interface_card_capabilities": {
                                    "SR-IOV": true,
                                    "mirroring": false
                                },
                                "storage": {
                                    "size_unit": "GB",
                                    "persistence": false,
                                    "size": 11
                                },
                                "network_interface_bandwidth": "",
                                "platform_pcie_parameters": {
                                    "SR-IOV": true,
                                    "device_pass_through": true
                                },
                                "vcpus": 1,
                                "vswitch_capabilities": {
                                    "version": "2.0",
                                    "type": "ovs",
                                    "overlay_tunnel": "GRE"
                                },
                                "data_processing_acceleration_library": "",
                                "memory": 2,
                                "memory_parameters": {
                                    "large_pages_required": false,
                                    "numa_allocation_policy": ""
                                },
                                "cpu_support_accelerator": "AES-NI"
                            },
                            "bootstrap_script": "",
                            "alias": "controller",
                            "networking_resources": "",
                            "monitoring_parameters_specific": [],
                            "id": "vdu0",
                            "vm_image": "http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img",
                            "controller": true,
                            "connection_points": [
                                {
                                    "vlink_ref": "vl0",
                                    "id": "CP3plm"
                    }
                ],
                            "monitoring_parameters": [],
                            "scale_in_out": {
                                "minimum": 1,
                                "maximum": 1
                            },
                            "vm_image_md5": "a78c7c73ceb2feeb20d8cd82a4f97da3",
                            "vm_image_format": "qcow2"
            }
        ],
                    "name": "2016-12-05-10-10-vhg",
                    "created_at": "2016-05-13T08:40:48Z",
                    "modified_at": "2016-05-13T08:40:48Z",
                    "provider_id": 7,
                    "trade": false,
                    "descriptor_version": "1",
                    "deployment_flavours": [
                        {
                            "vdu_reference": [
                    "vdu0"
                ],
                            "constraint": "",
                            "flavour_key": "gold",
                            "vlink_reference": [
                    "vl0",
                    "vl1"
                ],
                            "id": "flavor0",
                            "assurance_parameters": [
                                {
                                    "violation": [
                                        {
                                            "interval": 360,
                                            "breaches_count": 2
                            }
                        ],
                                    "value": 95,
                                    "penalty": {
                                        "type": "Discount",
                                        "expression": 10,
                                        "validity": "P1D",
                                        "unit": "%"
                                    },
                                    "formula": "load_longterm GE 95",
                                    "rel_id": "param0",
                                    "id": "load_longterm",
                                    "unit": "%"
                    }
                ]
            }
        ],
                    "version": "1",
                    "vnf_lifecycle_events": [
                        {
                            "authentication_username": "root",
                            "driver": "ssh",
                            "authentication_type": "PubKeyAuthentication",
                            "authentication": "",
                            "authentication_port": 22,
                            "flavor_id_ref": "flavor0",
                            "events": {
                                "start": {
                                    "command": "/root/start",
                                    "template_file": "{\"controller\":\"get_attr[vdu0, networks, net0, 0]\"}",
                                    "template_file_format": "JSON"
                                },
                                "stop": {
                                    "command": "/root/stop",
                                    "template_file": "{}",
                                    "template_file_format": "JSON"
                                }
                            },
                            "vnf_container": "/root"
            }
        ],
                    "billing_model": {
                        "model": "RS",
                        "price": {
                            "min_per_period": 1,
                            "max_per_period": 1,
                            "setup": 1,
                            "unit": "EUR"
                        },
                        "period": ""
                    },
                    "provider": "viotech",
                    "release": "T-NOVA",
                    "vlinks": [
                        {
                            "leaf_requirement": "Unlimited",
                            "connectivity_type": "E-LINE",
                            "vdu_reference": [
                    "vdu0"
                ],
                            "external_access": true,
                            "connection_points_reference": [
                    "CP3plm",
                    "CPqzat"
                ],
                            "access": true,
                            "alias": "mgnt",
                            "dhcp": true,
                            "root_requirement": "Unlimited",
                            "qos": "",
                            "id": "vl0"
            }
        ],
                    "type": "test",
                    "description": "test sample vnfd",
                    "id": 1618
                }
        }
    ];

    });
