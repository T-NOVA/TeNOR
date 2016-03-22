'use strict';

angular.module('tNovaApp')
    .controller('postmanController', function ($scope, nsService, vnfService, $modal, $http) {

        $scope.sendPOST = function (data) {
            console.log(data);
            if (data.jsonTemplate.name === "") {
                $scope.post.response = "Invalid name";
                return;
            }

            if (data.jsonTemplate.state === "") {
                $scope.post.response = "Invalid state";
                return;
            }

            if ($scope.selectedType === "VNF") {
                data.url = "apis.t-nova.eu/orchestrator/vnfs";
            } else if ($scope.selectedType === "NS") {
                data.url = "apis.t-nova.eu/orchestrator/network-services";
            }
            if (data.url === "apis.t-nova.eu/orchestrator/network-services") {
                if (data.jsonTemplate.version === "") {
                    $scope.post.response = "Invalid version";
                    return;
                }
                nsService.post(data.jsonTemplate).then(function (state, data) {
                    console.log(data);
                    $scope.post.response = "Inserted correctly";
                });
            } else if (data.url === "apis.t-nova.eu/orchestrator/vnfs") {
                vnfService.post(data.jsonTemplate).then(function (state, data) {
                    console.log(data);
                    $scope.post.response = "Inserted correctly";
                });
            }
        };

        $scope.selectType = ["VNF", "NS"];
        //{"name": "", "description": "", "vnf_image": "", "vnf_manager": ""}
        $scope.selectTemplates = [
            {
                "ns_id": "ns-eucnc",
                "name": "NS name",
                "description": "eUCNC Demo",
                "vendor": "",
                "version": "1.0",
                "vnfs": [
    "1"
  ],
                "vnffgd": null,
                "vld": null,
                "vnf_dependencies": [
    "1"
  ],
                "lifecycle_events": [
                    {
                        "initialization": "URI for the initialization script"
    },
                    {
                        "termination": "URI for the termination script"
    },
                    {
                        "scaling": "URI for the scaling script"
    }
  ],
                "auto_scale_policy": null,
                "created_at": "2015-06-22T14:03:16.463Z",
                "updated_at": "2015-06-22T14:03:16.463Z",
                "monitoring_parameters": [
                    {
                        "id": 1,
                        "name": "availability",
                        "description": "Percentage of time the NS has been available over the last 365 days",
                        "definition": null,
                        "unit": "%",
                        "ns_id": 1
    },
                    {
                        "id": 2,
                        "name": "ram-consumption",
                        "description": "Amount of RAM memory consumed by the service",
                        "definition": null,
                        "unit": "MB",
                        "ns_id": 1
    }
  ],
                "service_deployment_flavour": [
                    {
                        "id": 1,
                        "flavour_key": "",
                        "ns_id": 1,
                        "constituent_vnf": [
                            {
                                "id": 1,
                                "vnf_reference": "1",
                                "vnf_flavour_id_reference": "",
                                "redundancy_model": "",
                                "affinity": "",
                                "capability": "",
                                "number_of_instances": ""
        }
      ]
    }
  ],
                "assurance_parameters": [
                    {
                        "id": 1,
                        "param_id": "availability",
                        "value": "GT(min(vnfs[1].availability, vnfs[2].availability))",
                        "ns_id": 1,
                        "violation": {
                            "id": 1,
                            "breaches_count": "5",
                            "interval": "120",
                            "penalty": "not included, as they're not relevant to the Orchestrator"
                        }
    },
                    {
                        "id": 2,
                        "param_id": "ram-consumption",
                        "value": "LT(add(vnfs[1].memory-consumption, vnfs[2].memory-consumption, 100))",
                        "ns_id": 1,
                        "violation": {
                            "id": 2,
                            "breaches_count": "5",
                            "interval": "120",
                            "penalty": "not included, as they're not relevant to the Orchrstrator"
                        }
    }
  ],
                "connection_points": [
                    {
                        "id": 1,
                        "name": null,
                        "ns_id": 1
    }
  ]
}, {
                id: "vnf",
                type: "Virtual Network Function",
                content: {
                    "vnf_id": "vnf1",
                    "vendor": "NCSRD",
                    "descriptor_version": "1.0.0",
                    "version": "",
                    "vdus": [
                        {
                            "vm_image": "DPI.qcow2",
                            "computation_requirements": "High",
                            "lifecycle_event": " ",
                            "constraint": " ",
                            "high_availability": "0",
                            "scale_in_out": "0",
                            "OpenStack_Flavour": "to be added",
                            "hypervisor": {
                                "hypervisor_type": "QEMU",
                                "hypervisor_version": "1.0.0.6.0.0.2",
                                "hypervisor_address_translation_support": " "
                            },
                            "cpu": {
                                "cpu_instruction_set_extension": "VMX",
                                "cpu_model": "Intel E5-2680 v2",
                                "cpu_core_reservation": "2"
                            },
                            "memory": {
                                "number_of_large_pages_required_per_vdu": "2"
                            },
                            "vnfc": {
                                "connection_point": [
                                    {
                                        "virtual_link_reference": "eth0",
                                        "virtual_network_bandwidth": "10",
                                        "type": "external"
                                    },
                                    {
                                        "virtual_link_reference": "eth1",
                                        "virtual_network_bandwidth": "10",
                                        "type": "internal"
                                    }
                                ]
                            }
                        }
                    ],
                    "deployment_flavour": {
                        "flavour_key": "1",
                        "constituent_vdu": [
                            {
                                "vdu_reference": "1",
                                "number_of_instances": "1",
                                "constituent_vnfc": "1"
                            }
                        ]
                    },
                    "auto_scale_policy": "",
                    "manifest_file": "",
                    "manifest_file_security": ""
                }
            }
        ];
        $scope.post = {};
        $scope.post.jsonTemplate = "";
        $scope.post.url = "http://84.88.40.198:8000/api/";
        $scope.post.response = "";
        $scope.selectedItem = {};

        $scope.openPostman = function () {
            $scope.selectedIcon = "POST";
            $modal({
                title: "REST Client",
                content: "",
                template: "partials/t-nova/modals/postman.html",
                show: true,
                scope: $scope,
            });
        };
        $scope.update = function () {
            console.log($scope.selectedItem);
            console.log($scope.selectedItem.content);
            $scope.post.jsonTemplate = $scope.selectedItem.content;
            if ($scope.selectedItem.id === "ns") $scope.post.url = "http://84.88.40.198:8000/api/network-services";
            else if ($scope.selectedItem.id === "vnf") $scope.post.url = "http://84.88.40.198:8000/api/virtual-network-functions";
        };

        $scope.loadFile = function (element) {
            $scope.$apply(function (scope) {
                var file = element.files[0];
                var reader = new FileReader();
                reader.onload = function (e) { //event waits the file content
                    $scope.post.jsonTemplate = reader.result;
                };
                reader.readAsText(file);
            });
        };

    });
