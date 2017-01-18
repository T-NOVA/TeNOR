'use strict';

angular.module('tNovaApp')
    .controller('nsController', function ($scope, $stateParams, $filter, tenorService, $interval, $modal, $location, AuthService, $window, $alert) {

        $scope.descriptor = {};
        $scope.descriptor_options = { mode: 'code' };
        $scope.obj = {data: {}, options: { mode: 'code' }};

        $scope.registeredDcList = [];
        tenorService.get("modules/services/type/mapping").then(function (data) {
            if (data === undefined) return;
            $scope.serviceMapping = data;
        });
        var page_num = 20;
        var page = 1;
        $scope.dataCollection = [];
        $scope.getServiceList = function (page) {
            tenorService.get('network-services?offset=' + page + '&limit=' + page_num).then(function (data) {
                if (data.length > 0) {
                    $scope.dataCollection = _.sortBy($scope.dataCollection.concat(data), function (o) {
                        var dt = new Date(o.created_at);
                        return -dt;
                    });
                    if(data.length == page_num){
                        page++;
                        $scope.getServiceList(page);
                    }
                }
            });
        };

        $scope.restartServiceList = function (page) {
            $scope.dataCollection = [];
            $scope.getServiceList(page);
        };

        $scope.getServiceList(page);
        var promise = $interval(function () {
            $scope.restartServiceList(page);
        }, defaultTimer);

        $scope.deleteDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                templateUrl: "views/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });
        };
        $scope.deleteItem = function (id) {
            tenorService.delete('network-services/' + id).then(function (data) {
                $scope.restartServiceList(1);
            });
            this.$hide();
        };

        $scope.showDescriptor = function (data) {
            $scope.jsonObj = JSON.stringify(data, undefined, 4);
            $modal({
                title: "Network Service Descriptor - " + data.id,
                content: JSON.stringify(data, undefined, 4),
                templateUrl: "views/t-nova/modals/descriptors.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
        });

        $scope.instantiateDialog = function (nsd) {
            $scope.getPoPs();
            $scope.nsd = nsd;
            $scope.object = {};
            $scope.object.vnfds = nsd.vnfds;
            $scope.object.ns_id = nsd.id;
            $scope.object.callbackUrl = "https://httpbin.org/post";
            $scope.object.pop_id = null;
            //$scope.object.flavour = nsd.sla[0].sla_key;
            $modal({
                title: "Instantiation - " + nsd.id,
                templateUrl: "views/t-nova/modals/nsInstantiation.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.instantiate = function (instance) {
            console.log(instance);
            var error = undefined;
            if (instance.flavour === undefined) {
                error = "Flavour not selected."
            } else {
                if (instance.select_pop == 0) { //use service Mapping
                    if (instance.mapping_id == null) {
                        error = "Mapping not selected."
                    }
                    delete instance["pop_id"];
                } else { //use selected PoP
                    if (instance.pop_id == null) {
                        error = "PoP not selected."
                    } else if (true) {
                        console.log(instance.vnf_pop);
                    }
                    delete instance["mapping_id"];
                }
            }
            if (error !== undefined) {
                $alert({
                    title: "Error: ",
                    content: error,
                    placement: 'top',
                    type: 'danger',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container_modal',
                    duration: 5
                });
                return;
            }
            delete instance["select_pop"];
            console.log(instance);
            tenorService.post('ns-instances', instance).then(function (data) {
                console.log(data);
                $alert({
                    title: "Creating new instance... ",
                    content: "",
                    placement: 'top',//top-right
                    type: 'success',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
            });

            this.$hide();
        };

        $scope.getPoPs = function () {
            $scope.registeredDcList = [];
            tenorService.get("pops/dc").then(function (d) {
                $scope.registeredDcList = d;
            });
        };

        $scope.go = function (hash) {
            $location.path(hash);
        };

        $scope.uploadDialog = function(){
            $modal({
                title: "Upload a NSD",
                templateUrl: "views/t-nova/modals/upload.html",
                show: true,
                scope: $scope,
            });
        }

        $scope.uploadFile = function(files){
            var fd = new FormData();
            //Take the first selected file
            //fd.append('file', files[0]);
            //var obj = JSON.parse(files);
            var obj = files;
            console.log(obj);
            tenorService.post('network-services', obj).then(function (data) {
                console.log(data);
                $scope.restartServiceList(1);
            });
            this.$hide();
        }

        $scope.loadFile = function (element) {
            var file = element.files[0];
            var reader = new FileReader();
            reader.onload = function () { //event waits the file content
                $scope.$apply(function () {
                    //$scope.descriptor = JSON.stringify(JSON.parse(reader.result), undefined, 4); //JSON.parse(reader.result);
                    $scope.obj.data = JSON.parse(reader.result); //JSON.parse(reader.result);
                });
            };
            reader.readAsText(file);
        };

    })
    .controller('nsInstancesController', function ($scope, $location, $stateParams, $filter, tenorService, $interval, $modal) {
        var promise;

        $scope.go = function (hash) {
            $location.path(hash);
        };

        $scope.data = [];
        $scope.updateInstanceList = function () {
            tenorService.get("ns-instances").then(function (data) {
                //                data = data.reverse();
                $scope.dataCollection = _.sortBy(data, function (o) {
                    var dt = new Date(o.created_at);
                    return -dt;
                });
            });
        };

        $scope.updateInstanceList();
        var promise = $interval(function () {
            $scope.updateInstanceList();
        }, defaultTimer2);

        $scope.stop = function (id) { //change status in the repo
            tenorService.put("ns-instances/" + id + '/stop', '').then(function (data) {});
        };

        $scope.start = function (id) { //change status in the repo
            tenorService.put("ns-instances/" + id + '/start', '').then(function (data) {});
        };

        $scope.deleteDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                templateUrl: "views/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.deleteItem = function (id) {
            tenorService.delete("ns-instances/" + id).then(function (data) {
                $scope.updateInstanceList();
            });
            this.$hide();
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
        });

        $scope.showDescriptor = function (data) {
            $scope.d = data;
            $scope.d.mapping_total_time = Date.parse($scope.d.mapping_time) - Date.parse($scope.d.created_at);
            $scope.d.instantiation_total_time = Date.parse($scope.d.instantiation_end_time) - Date.parse($scope.d.created_at);
            $scope.jsonObj = JSON.stringify(data, undefined, 4);
            $modal({
                title: "Network Service Instance Descriptor - " + data.id,
                content: JSON.stringify(data, undefined, 4),
                templateUrl: "views/t-nova/modals/info/nsInstance.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.scale_out = function (id) {
            tenorService.post("ns-instances/scaling/"+id+"/scale_out", {}).then(function (data) {
                $scope.updateInstanceList();
            });
        };

        $scope.scale_in = function (id) {
            tenorService.post("ns-instances/scaling/"+id+"/scale_in", {}).then(function (data) {
                $scope.updateInstanceList();
            });
        };
    })
    .controller('nsMonitoringController', function ($scope, $stateParams, $filter, mDataService, $interval, tenorService) {
        var promise, promise1, promise2;
        $scope.monitoringData = new vis.DataSet()
        $scope.instanceId = $stateParams.id;
        if ($stateParams.id) {
            tenorService.get("ns-instances/" + $stateParams.id).then(function (instance) {
                $scope.instance = instance;
                tenorService.get("network-services/" + $scope.instance.nsd_id).then(function (nsd) {
                    $scope.tableData = [];
                    console.log(nsd);
                    /*nsd.monitoring_parameters.forEach(function (m) {
                        $scope.tableData.push({
                            type: m.desc,
                            valueType: m.metric
                        });
                    })*/
                    nsd.sla.forEach(function (sla) {
                        sla.assurance_parameters.forEach(function (m) {
                            $scope.tableData.push({
                                type: m.name,
                                valueType: m.name,
                                threshold: m.value,
                                formula: m.formula
                            });
                        })
                    });
                });
            });
        };

        $scope.oldType = "";
        $scope.options = {
            legend: true,
            max: '2020-12-31',
            min: '2016-01-01',
            start: vis.moment().add(-30, 'hours'), // changed so its faster
            end: vis.moment(),
            sort: true,
            sampling: false,
            dataAxis: {
                customRange: {
                    left: {},
                    showMinorLabels: true
                },
                left: {
                    format: function (value) {
                        return '' + value.toPrecision();
                    }
                }
            },
            defaultGroup: 'Scatterplot'
        };
        $scope.reloadGraph = function (type, threshold) {
            $interval.cancel(promise1);
            $interval.cancel(promise2);
            $scope.monitoringData.clear();
            $scope.newType = type;
            if ($scope.oldType !== type) {
                $scope.oldType = type;
            }
            var groups = new vis.DataSet();
            var items = [];
            groups.add({
                id: 0,
                content: type,
                options: {
                    className: "custom-line-style",
                    drawPoints: {
                        style: 'circle' // square, circle
                    }
                }
            });
            groups.add({
                id: 1,
                content: "Threshold",
                className: "custom-line-style",
                options: {
                    drawPoints: false
                }
            });
            $scope.data = {
                items: new vis.DataSet(items),
                groups: groups
            };
            $scope.data.items.add({
                x: '2016-01-01',
                y: parseFloat(threshold.split("(")[1].split(")")[0]),
                group: 1
            });
            $scope.data.items.add({
                x: '2020-12-31',
                y: parseFloat(threshold.split("(")[1].split(")")[0]),
                group: 1
            });

            $scope.showGraphWithHistoric(type);
        }

        $scope.showGraphWithHistoric = function (type) {
            $scope.graph_name = type;
            var historicInterval = 1000; //seconds
            var realTimeInterval = 61000; //seconds
            var lastStartDate = Math.floor(new Date().getTime() / 1000);
            var lastEndDate = Math.floor(new Date().getTime() / 1000);
            var url;
            promise1 = $interval(function () {
                url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=ns&metric=" + type + "&end=" + lastEndDate;
                tenorService.get(url).then(function (data) {
                    if (data.length == 0) {
                        $interval.cancel(promise1);
                        return
                    }
                    _.each(data, function (t) {
                        t['x'] = t.date * 1000;
                        t['y'] = parseFloat(t.value);
                        t['group'] = 0;
                    });
                    $scope.data.items.add(data);
                    lastEndDate = data[data.length - 1].date - 1;
                });
            }, historicInterval);
            promise2 = $interval(function () {
                url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=ns&metric=" + type + "&start=" + lastStartDate;
                tenorService.get(url).then(function (data) {
                    if (data.length == 0) return
                    _.each(data, function (t) {
                        t['x'] = t.date * 1000;
                        t['y'] = parseFloat(t.value);
                        t['group'] = 0;
                    });
                    $scope.data.items.add(data);
                    lastStartDate = data[data.length - 1].date;
                });
            }, realTimeInterval);
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
            if (promise1) {
                $interval.cancel(promise1);
            }
            if (promise2) {
                $interval.cancel(promise2);
            }
        });
    });
