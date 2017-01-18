'use strict';

angular.module('tNovaApp')
    .controller('descriptionCreationController', function ($scope, $filter, $alert, tenorService) {

        //load NSD schema in tv4
        $.getJSON('../../schemas/nsd_schema.json', function (response) {
            var jsonSchema = response;
            tv4.addSchema("nsd_schema", jsonSchema);
        });

        $scope.selectedIcons = [];
        $scope.nsds = [];

        $scope.getFlavours = function (vnfd) {
            if (vnfd == undefined) return;
            return $scope.vnfs.filter(function (d) {
                return d.vnfd.id === vnfd;
            })[0].vnfd.deployment_flavours;
        };

        $scope.getEvents2 = function (index, type) {
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

        $scope.getEvents = function (type, vnf_id) {
            var vnfs = $scope.nsd.sla.filter(function (sla) {
                return sla.constituent_vnfs.filter(function (c_vnf) {
                    return c_vnf.vnf_ref_id === vnf_id;
                })
            });
            return vnfs;
        };

        $scope.addNSD = function (nsd) {
            $scope.nsds.push(nsd)
        };

        $scope.addSla = function () {
            var newItemNo = $scope.nsd.sla.length + 1;
            $scope.nsd.sla.push({
                'id': 'sla' + newItemNo,
                'constituent_vnfs': []
            });
        };

        $scope.addConstituentVnf = function (sla_index) {
            var newItemNo = $scope.nsd.sla[sla_index].constituent_vnfs.length + 1;
            $scope.nsd.sla[sla_index].constituent_vnfs.push({});
        };

        $scope.addvLink = function () {
            var newItemNo = $scope.nsd.vld.virtual_links.length + 1;
            $scope.nsd.vld.virtual_links.push({
                'id': 'vld' + newItemNo,
                'connections': []
            });
        };

        $scope.addNew = function (type) {
            var newItemNo = $scope.nsd["'" + type + "'"].length + 1;
            $scope.nsd["'" + type + "'"].push({
                'id': type + newItemNo
            });
        };

        $scope.addEvent = function (type) {
            $scope.nsd.lifecycle_events[type].push({
                'vnf_event': type
            });
        };

        $scope.addConnection = function (virtual_link_id) {
            $scope.nsd.vld.virtual_links[virtual_link_id].connections.push();
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

        $scope.removeConstituentVNF = function (sla_id, id) {
            console.log(sla_id)
            $scope.nsd.sla[sla_id].constituent_vnfs[id].splice(id, id);
            var newItemNo = $scope.choices.length - 1;
            if (newItemNo !== 0) {
                $scope.nsd.sla.pop();
            }
        };

        $scope.removeEvent = function (type, id) {
            $scope.nsd.lifecycle_events[type][id].splice(id, id);
        };

        $scope.submitNsd = function () {

            $scope.registerForm = {};
            //$scope.registerForm.sla = [];

            var nsd = {
                "nsd": $scope.nsd
            };
            $scope.nsd.vnfds.map(String);
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


            console.log("NSD Correct...");

            tenorService.post('network-services', $scope.registerForm).then(function (data) {
                console.log(data);
                //window.location = "#!/nsInstances/";
            });
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
            "vld": {
                "virtual_links": []
            },
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
                }
            ],
                "B": [
                    {
                        "type": "item",
                        "id": 7
                },
                    {
                        "type": "container",
                        "id": "2",
                        "columns": [
                        [
                                {
                                    "type": "item",
                                    "id": "9"
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
                                    ]
                                ]
                            },
                                {
                                    "type": "item",
                                    "id": "15"
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


        tenorService.get('vnfs?limit=1000').then(function (data) {
            $scope.vnfs = data;
        });

        $scope.connection_link_types = [
            {
                type: 'E-LINE',
                description: 'Point-2-Point (E-LINE)'
            },
            {
                type: 'E-TREE',
                description: 'Point-2-Multipoint (E-TREE)'
            },
            {
                type: 'E-LAN',
                description: 'Lan (E-LAN)'
            }
         ];


        $scope.generic_monitoring_parameters = [
            {
                metric: "cpuidle",
                desc: "CPU Idle",
                unit: '%'
            },
            {
                metric: "cpu_util",
                desc: "CPU Utilization",
                unit: '%'
            },
            {
                metric: "fsfree",
                desc: "Free Storage",
                unit: 'GB'
            },
            {
                metric: "memfree",
                desc: "Free Memory",
                unit: 'MB'
            },
            {
                metric: "network_incoming",
                desc: "Network Incoming",
                unit: 'Mbps'
            },
            {
                metric: "network_outgoing",
                desc: "Network Outgoing",
                unit: 'Mbps'
            },
            {
                metric: "load_shortterm",
                desc: "Load Average (1 Minute)",
                unit: '%'
            },
            {
                metric: "load_midterm",
                desc: "Load Average (5 Minutes)",
                unit: '%'
            },
            {
                metric: "load_longterm",
                desc: "Load Average (15 Minutes)",
                unit: '%'
            },
            {
                metric: "processes_blocked",
                desc: "Blocked Processes",
                unit: 'INT'
            },
            {
                metric: "processes_paging",
                desc: "Paging Processes",
                unit: 'INT'
            },
            {
                metric: "processes_running",
                desc: "Running Processes",
                unit: 'INT'
            },
            {
                metric: "processes_sleeping",
                desc: "Sleeping Processes",
                unit: 'INT'
            },
            {
                metric: "processes_stopped",
                desc: "Stopped Processes",
                unit: 'INT'
            },
            {
                metric: "processes_zombie",
                desc: "Zombie Processes",
                unit: 'INT'
            }
    ];
        _.each($scope.vnfs, function (d) {
            d.vnfd.id = "" + d.vnfd.id;
        })

    });
