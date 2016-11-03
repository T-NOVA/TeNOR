'use strict';

angular.module('tNovaApp')
    .controller('infrastructureRepositoryController', function ($rootScope, $scope, $http, $q, localStorageService, $interval, $modal, $timeout, infrRepoService, $loading, tenorService) {

        var url = '';
        $scope.showPop = false;
        $scope.rootElement = {};
        $scope.tree = [];
        $scope.infrModel = [];

        $scope.physicalResources = false;
        $scope.virtualResources = false;

        $scope.showTopology = false;

        tenorService.get("modules/services/type/infr_repo").then(function (data) {
            if (data === undefined) return;
            console.log(data);
            $scope.infr_repo_url = data[0].host + ":" + data[0].port;
            console.log($scope.infr_repo_url);
            $scope.getPops();
        });

        $scope.ui_handler = function (uid, type) {
            var selected;
            console.log(uid + " " + type);
            if (type === "pop") {
                $scope.tree.forEach(function (entry) {
                    console.log(entry);
                    if (entry.uid === uid) {
                        selected = entry;
                        //$scope.tree.expand_branch();//not working...
                        $scope.my_tree_handler(selected);
                    }
                });
            }
        };

        $scope.my_tree_handler = function (selected) {
            $scope.topologyData = {};
            if (selected.classes[0] === "pop") {
                $scope.showPop = false;
                $scope.showLayers = true;
                $scope.showTopology = false;
                $timeout(function () {
                    $scope.$broadcast('rootElements', $rootScope.rootElement[selected.label]);
                });
            }
        };

        $scope.network_options = {
            nodes: {
                shape: 'dot',
                size: 20,
                font: {
                    size: 15,
                    color: '#ffffff'
                },
                borderWidth: 2
            },
            edges: {
                width: 2
            },
            groups: {
                diamonds: {
                    color: {
                        background: 'red',
                        border: 'white'
                    },
                    shape: 'diamond'
                },
                dotsWithLabel: {
                    label: "I'm a dot!",
                    shape: 'dot',
                    color: 'cyan'
                },
                mints: {
                    color: 'rgb(0,255,140)'
                },
                icons: {
                    shape: 'icon',
                    icon: {
                        face: 'FontAwesome',
                        code: '\uf0c0',
                        size: 50,
                        color: 'orange'
                    }
                },
                source: {
                    color: {
                        border: 'white'
                    }
                }
            }
        };

        $scope.generateGraph = function (popId) {
            $scope.showTables = false;
            if (popId === undefined) popId = 0;
            //$scope.getResourcesByPoP(popId);

            console.log("Generate graph");
            $scope.showPop = true;
            $scope.showLayers = false;
            $scope.showTopology = true;
            var data = {};
            data.nodes = [];
            data.links = [];
            $scope.nodes = new vis.DataSet();
            $scope.edges = new vis.DataSet();
            $rootScope.network_data = {
                nodes: $scope.nodes,
                edges: $scope.edges
            };

            console.log($rootScope.network_data);
            $rootScope.$broadcast('completeTopologyData', data);
            console.log($scope.infrModel);
            //var pop = $rootScope.rootElement["Intel Ireland's Leixlip Campus, Kildare, Ireland"];
            var pop = $scope.infrModel[popId];
            $loading.start('topology');
            for (var layers in pop.resources) {

                console.log(layers);
                if (layers !== "virtual_resource") continue;
                console.log(layers);
                for (var elType in pop.resources[layers]) {
                    if (elType === 'port') continue;
                    if (elType === 'cache') continue;
                    if (elType === 'snapshot') continue;
                    if (elType === 'net') continue;
                    if (elType === 'floatingip') continue;
                    if (elType === 'pu') continue;
                    url = 'pop/' + $scope.infrModel[popId]['occi.epa.popuuid'] + '/' + elType + '/';
                    infrRepoService.get($scope.infr_repo_url, url).get(url).then(function (_data) {
                        if (_data.length === 0)
                            $scope.dataCollection = [];
                        var j = 0;
                        angular.forEach(_data, function (res) {
                            infrRepoService.get($scope.infr_repo_url, res.identifier.slice(1)).then(function (resource) {
                                //console.log(resource)
                                $scope.dataCollection.push(resource.attributes);
                                data.nodes.push({
                                    id: resource['identifier'],
                                    label: resource.attributes['occi.epa.name'],
                                    type: resource.attributes['occi.epa.resource_type'],
                                    group: resource.attributes['occi.epa.resource_type']
                                        //group: resource.attributes['occi.epa.index_type']
                                });
                                angular.forEach(resource.links, function (link) {
                                    data.links.push({
                                        from: link['source'],
                                        to: link['target']
                                    });
                                })
                                j++;
                                if (j >= _data.length) {
                                    $loading.finish('topology');
                                    $scope.drawing_layer = resource.attributes['occi.epa.resource_type'];
                                    $scope.drawing_resources = resource.attributes['occi.epa.index_type'];
                                    $rootScope.$broadcast('completeTopologyData', data);
                                }
                            })
                        });
                    })
                }
            }

            $timeout(function () {
                console.log(data);
                //$rootScope.$broadcast('completeTopologyData', data);
            }, 20000);
        };

        $scope.filter = function (popId) {
            var data = {};
            data.nodes = [];
            data.links = [];
            $rootScope.$broadcast('completeTopologyData', data);
            popId = 0;
            var pop = $scope.infrModel[popId];
            for (var i = 0; i < $scope.selectedLayer.length; i++) {
                if ($scope.selectedLayer[i].isChecked !== true) continue;
                var layer = $scope.selectedLayer[i].type;
                for (var elType in pop.resources[layer]) {
                    console.log(elType);

                    if (elType === 'port') continue;
                    if (elType === 'cache') continue;
                    if (elType === 'snapshot') continue;
                    if (elType === 'net') continue;
                    if (elType === 'floatingip') continue;

                    url = 'pop/' + $scope.infrModel[popId]['occi.epa.popuuid'] + '/' + elType + '/';
                    infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                        if (_data.length === 0) $loading.finish('table');
                        $scope.dataCollection = [];
                        var j = 0;
                        angular.forEach(_data, function (res) {
                            infrRepoService.get($scope.infr_repo_url, res.identifier.slice(1)).then(function (resource) {
                                data.nodes.push({
                                    id: resource['identifier'],
                                    label: resource.attributes['occi.epa.name'],
                                    type: resource.attributes['occi.epa.resource_type'],
                                    group: resource.attributes['occi.epa.resource_type']
                                        //group: resource.attributes['occi.epa.index_type']
                                });
                                angular.forEach(resource.links, function (link) {
                                    data.links.push({
                                        from: link['source'],
                                        to: link['target']
                                    });
                                })
                                j++;
                                if (j >= _data.length) {
                                    $scope.drawing_layer = resource.attributes['occi.epa.resource_type'];
                                    $scope.drawing_resources = resource.attributes['occi.epa.index_type'];
                                    $rootScope.$broadcast('completeTopologyData', data);
                                }
                            });

                        })
                    });
                }
            }

            //data.links = $rootScope.edges;

            $timeout(function () {
                //$rootScope.$broadcast('completeTopologyData', data);
            }, 20000);
        };

        $scope.selectedLayer = [
            {
                name: "virtual",
                type: "physical_resource",
                id: 0,
                isChecked: false
            },
            {
                name: "physical",
                type: "physical_resource",
                id: 1,
                isChecked: false
            },
            {
                name: "service",
                id: 2,
                isChecked: false
            },
            {
                name: "vnf",
                id: 3,
                isChecked: false
            }
        ];

        $scope.types = [];
        $scope.getTypes = function () {
            url = '-/';
            infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                _data.forEach(function (_data) {
                    $scope.types.push({
                        id: _data.term,
                        location: _data.location
                    });
                });

            }).finally(function () {
                console.log("END");
                // $scope.generateTemplate();
            });
        };

        $scope.getTypes();

        $scope.virtualType = ['stack', 'vm', 'port', 'net', 'volume', 'snapshot', 'floatingip', 'router', 'controller', 'hypervisor', 'cinder'];
        $scope.physicalType = ['machine', 'bridge', 'pcidev', 'osdev', 'socket', 'cache', 'core', 'core', 'pu'];

        $scope.getPops = function () {
            $loading.start('pops');
            $scope.showPops = true;
            $scope.showPop = false;

            url = 'pop/';
            infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                $scope.pops = _data;
                if (_data.length === 0) $loading.finish('pops');
                $scope.infrModel = [];
                angular.forEach(_data, function (pop, index, array) {
                    url = pop.identifier.slice(1);
                    infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                        $scope.infrModel.push(_data.attributes);
                        $scope.infrModel[$scope.infrModel.length - 1].resources = {};

                        $scope.infrModel[$scope.infrModel.length - 1].resources.physical_resource = {};
                        $scope.infrModel[$scope.infrModel.length - 1].resources.virtual_resource = {};
                        angular.forEach($scope.virtualType, function (type) {
                            $scope.infrModel[$scope.infrModel.length - 1].resources.virtual_resource[type] = [];
                        });
                        angular.forEach($scope.physicalType, function (type) {
                            $scope.infrModel[$scope.infrModel.length - 1].resources.physical_resource[type] = [];
                        });
                        $loading.finish('pops');
                    });
                });
            });
        };

        $scope.getResourcesByType = function (popId, type) {
            $loading.start('table');
            var type = $scope.types.filter(function (d) {
                return d.id === type;
            })[0];

            $scope.showPops = false;
            $scope.showPop = true;
            $scope.showTables = true;
            $scope.showTopology = false;
            url = 'pop/' + $scope.infrModel[popId]['occi.epa.popuuid'] + type.location;
            infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                if (_data.length === 0) $loading.finish('table');
                $scope.dataCollection = [];
                angular.forEach(_data, function (res) {
                    infrRepoService.get($scope.infr_repo_url, res.identifier.slice(1)).then(function (resource) {
                        if ($scope.infrModel[popId][resource.attributes['occi.epa.index_type']] === undefined) {
                            $scope.infrModel[popId][resource.attributes['occi.epa.index_type']] = [];
                        }
                        if ($scope.infrModel[popId][resource.attributes['occi.epa.index_type']][type.id] === undefined) {
                            $scope.infrModel[popId][resource.attributes['occi.epa.index_type']][type.id] = [];
                        }
                        if (resource.attributes['occi.epa.index_type'] !== undefined)
                            $scope.infrModel[popId][resource.attributes['occi.epa.index_type']][type.id].push(resource.attributes);
                        $scope.dataCollection.push(resource.attributes);
                        $loading.finish('table');
                        //$scope.dataCollection = resource.attributes;
                    })
                });
            })
        };

        $scope.showResources = function (type) {
            $scope.showTables = true;
            $scope.showTopology = false;
            if (type === 'phy') {
                $scope.physicalResources = true;
                $scope.virtualResources = false;
            }
            if (type === 'virt') {
                $scope.physicalResources = false;
                $scope.virtualResources = true;
            }
        };

        $scope.getPoP = function (popId) {
            $scope.showPops = false;
            $scope.showPop = true;
            $scope.pop = {};
            console.log(popId);
            $scope.pop = $scope.infrModel[popId];
            $scope.pop.id = popId;
            //$scope.getResourcesByPoP(popId);
            return;
            url = 'pop/' + $scope.infrModel[popId]['occi.epa.popuuid'].slice(1);
            infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                console.log(_data);
                $scope.pop = _data.attributes;
            });
        };

        $scope.getResourcesByPoP = function (popId) {
            $scope.showPops = false;
            $scope.showPop = true;
            angular.forEach($scope.types, function (type) {
                if (type.id.indexOf("link") > -1) return;
                url = 'pop/' + $scope.infrModel[popId]['occi.epa.popuuid'] + type.location;
                infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                    angular.forEach(_data, function (res, index, _ary) {
                        infrRepoService.get($scope.infr_repo_url, res.identifier.slice(1)).then(function (resource) {
                            if ($scope.infrModel[popId].resources[resource.attributes['occi.epa.index_type']] === undefined) {
                                $scope.infrModel[popId].resources[resource.attributes['occi.epa.index_type']] = [];
                            }
                            if ($scope.infrModel[popId].resources[resource.attributes['occi.epa.index_type']][type.id] === undefined) {
                                $scope.infrModel[popId].resources[resource.attributes['occi.epa.index_type']][type.id] = [];
                            }
                            if (resource.attributes['occi.epa.index_type'] !== undefined)
                                $scope.infrModel[popId].resources[resource.attributes['occi.epa.index_type']][type.id].push(resource.attributes);
                            console.log(index);
                        });
                    });
                });
            });
        };


        $scope.showDescriptor = function (data) {
            $scope.jsonObj = JSON.stringify(JSON.parse(data), undefined, 4);
            $modal({
                title: "Attributes",
                content: "",
                template: "views/t-nova/modals/descriptors.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.panels = [
            {
                "title": "Collapsible Group Item #1",
                "body": ""
          },
            {
                "title": "Collapsible Group Item #2",
                "body": ""
          }];

        $scope.panels.activePanel;

        $scope.startLoading = function (name) {
            $loading.start(name);
        };

        $scope.finishLoading = function (name) {
            $loading.finish(name);
        };

        $scope.options = {
            active: false, // Defines current loading state
            text: "",
            className: '', // Custom class, added to directive
            overlay: true, // Display overlay
            spinner: true, // Display spinner
            spinnerOptions: {
                lines: 12, // The number of lines to draw
                length: 7, // The length of each line
                width: 4, // The line thickness
                radius: 10, // The radius of the inner circle
                rotate: 0, // Rotation offset
                corners: 1, // Roundness (0..1)
                color: '#000', // #rgb or #rrggbb
                direction: 1, // 1: clockwise, -1: counterclockwise
                speed: 2, // Rounds per second
                trail: 100, // Afterglow percentage
                opacity: 1 / 4, // Opacity of the lines
                fps: 20, // Frames per second when using setTimeout()
                zIndex: 2e9, // Use a high z-index by default
                className: 'dw-spinner', // CSS class to assign to the element
                top: 'auto', // Center vertically
                left: 'auto', // Center horizontally
                position: 'relative' // Element position
            }
        };

    })
    .controller("popLayer", function ($rootScope, $scope, $filter, $modal) {
        $scope.tableDisplay = false;

        $scope.showTable = function (layer, name) {
            //          if(!$scope.tableDisplay) $scope.showTable2();
            //            $scope.tableDisplay = true;
            $scope.data = [];
            console.log("Show table: " + layer + " - " + name);
            $scope.data = $rootScope.rootElement["Intel Ireland's Leixlip Campus, Kildare, Ireland"][layer][name];
            console.log("Table reload");
            if (!$scope.tableDisplay) {
                console.log("inside");
                $scope.tableDisplay = true;
                $scope.showTable2();
            } else {
                //get new data
                $scope.tableParams.reload();
            }
        }

        $scope.showTable2 = function () {
            console.log("Show table");
            $scope.tableDisplay = true;
            $scope.tableParams = new ngTableParams({
                count: $scope.data.length,
                sorting: {
                    id: 'desc' // initial sorting
                },
            }, {
                total: $scope.data.length,
                getData: function ($defer, params) {
                    console.log("GEt Data");
                    console.log($scope.data);
                    var orderedData = params.sorting() ? $filter('orderBy')($scope.data, params.orderBy()) : $scope.data;
                    $defer.resolve(orderedData.slice((params.page() - 1) * params.count(), params.page() * params.count()));
                },
                $scope: {
                    $data: {}
                }
            });
        }

        $scope.showDescriptor = function (data) {
            $scope.jsonObj = JSON.parse(data);
            $modal({
                title: "Attributes",
                content: "",
                template: "partials/t-nova/modals/descriptors.html",
                show: true,
                scope: $scope,
            });
        };

    });

function treeToTreeUI(rootResource) {
    var tree = [];

    Object.keys(rootResource).forEach(function (p) {
        var pop = {
            label: p,
            children: [],
            classes: ['pop']
        };
        Object.keys(rootResource[p]).forEach(function (l) {
            var layer = {
                label: l,
                children: [],
                classes: ['layer']
            };
            Object.keys(rootResource[p][l]).forEach(function (t) {
                var type = {
                    label: t,
                    children: [],
                    classes: ['type']
                };
                layer.children.push(type);
            });
            pop.children.push(layer);
        });
        tree.push(pop);
    });
    return tree;
}

function createInfrRepoTreeModel2(jsonObject) {
    console.log(jsonObject);
}

function createInfrRepoTreeModel(jsonObject) {
    console.log(jsonObject);
    var root = [];
    var rootResource = {};
    var nodes = jsonObject.nodes;
    Object.keys(nodes).forEach(function (key) {
        var node = nodes[key];
        node.id = parseInt(key);
        if (rootResource[node.pop] === undefined) {
            console.log(node.pop);
            rootResource[node.pop] = {};
        }
        if (rootResource[node.pop][node.layer] === undefined) {
            rootResource[node.pop][node.layer] = {};
        }
        if (node.type !== undefined) {
            if (rootResource[node.pop][node.layer][node.type] === undefined) {
                rootResource[node.pop][node.layer][node.type] = [];
            }
            rootResource[node.pop][node.layer][node.type].push(node);
        } else console.log(node);
    });
    root.push(rootResource);
    return rootResource;
}

function createInfrRepoEdgesModel(jsonObject) {
    var root = [];
    var rootResource = {};
    var edges = jsonObject.edges;
    Object.keys(edges).forEach(function (key) {
        var edge = {};
        edge.from = parseInt(edges[key][0].substring(1, edges[key][0].length - 1));
        edge.to = parseInt(edges[key][1].substring(1, edges[key][1].length - 1));
        edge.label = edges[key][2];
        root.push(edge);
    });
    root.push(rootResource);
    return root;
}
