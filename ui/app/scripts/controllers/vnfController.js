'use strict';

angular.module('tNovaApp')
    .controller('vnfController', function ($scope, $stateParams, $filter, tenorService, $interval, $modal) {

        $scope.getVnfList = function () {
            tenorService.get('vnfs').then(function (data) {
                //$scope.data = data;
                $scope.dataCollection = data;
            });
        };

        $scope.getVnfList();
        var promise = $interval(function () {
            $scope.getVnfList();
        }, defaultTimer);

        $scope.deleteDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                template: "views/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });
        };
        $scope.deleteItem = function (id) {
            tenorService.delete('vnfs/' + id).then(function (data) {
                $scope.getVnfList();
            });
            this.$hide();
        };

        $scope.showDescriptor = function (data) {
            $scope.jsonObj = JSON.stringify(data, undefined, 4);
            $modal({
                title: "Virtual Network Function Descriptor - " + data.name,
                content: JSON.stringify(data, undefined, 4),
                template: "views/t-nova/modals/descriptors.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
        });

    })
    .controller('vnfInstancesController', function ($scope, $location, $filter, tenorService, $interval, $modal) {
        var promise;
        $scope.go = function (hash) {
            $location.path(hash);
        };

        $scope.data = [];
        $scope.updateInstanceList = function () {
            tenorService.get("vnf-provisioning/vnf-instances").then(function (data) {
                $scope.data = data;
                $scope.dataCollection = data;
            });
        };

        $scope.updateInstanceList();
        var promise = $interval(function () {
            $scope.updateInstanceList();
            //        }, defaultTimer);
        }, 120000);

        $scope.stop = function (instance) { //change status in the repo
            if (instance.status === 3) instance.status = 0;
            else if (instance.status === 0) instance.status = 3;
            //tenorService.put("vnf/" + instance.id, instance).then(function (data) {});
        };
        $scope.delete = function (id) {
            //tenorService.delete("vnf/" + id).then(function (data) {});
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
        });

        $scope.showDescriptor = function (data) {
            $scope.d = data;
            $scope.jsonObj = JSON.stringify(data, undefined, 4);
            console.log(data);
            $modal({
                title: "VNF Instance Descriptor - " + data._id,
                content: JSON.stringify(data, undefined, 4),
                template: "views/t-nova/modals/info/vnfInstance.html",
                show: true,
                scope: $scope,
            });
        };
    })
    .controller('vnfMonitoringController', function ($scope, $stateParams, $filter, mDataService, $interval, tenorService) {
        var promise;
        $scope.instanceId = $stateParams.id;
        if ($stateParams.id) {
            tenorService.get("vnf-provisioning/vnf-instances/" + $stateParams.id).then(function (instance) {
                $scope.instanceId = instance._id;
                $scope.instance = instance;

                tenorService.get("vnfs/" + $scope.instance.vnfd_reference).then(function (vnfd) {
                    $scope.tableData = [];
                    console.log(vnfd);
                    vnfd.vnfd.vdu.forEach(function (vdu) {
                        vdu.monitoring_parameters.forEach(function (m) {
                            $scope.tableData.push({
                                type: m.desc,
                                value: 0,
                                valueType: m.metric
                            });
                        })
                    });
                });
            });
        };

        $scope.metric;

        $scope.reloadGraph = function (type) {
            //$stateParams.id = "a0c9e9a1-9fa7-481f-8023-64a51e19cfb4";

            $interval.cancel(promise);
            $scope.graph_name = type;
            $scope.monitoringData.clear();

            console.log($scope.monitoringData);
            var url;
            if ($scope.monitoringData.length === 0) url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type;
            else url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type + "&start=" + $scope.monitoringData.get($scope.monitoringData.length - 1).date;

            tenorService.get(url).then(function (data) {
                console.log(data);
                angular.forEach(data, function (t) {
                    t.id = $scope.monitoringData.length;
                    t.x = t.date * 1000;
                    t.y = Math.floor(t.value);
                    $scope.monitoringData.add(t);
                })
            });

            promise = $interval(function () {

                console.log($scope.monitoringData);
                var url;
                if ($scope.monitoringData.length === 0) url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type;
                else url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type + "&start=" + $scope.monitoringData.get($scope.monitoringData.length - 1).date;

                tenorService.get(url).then(function (data) {
                    console.log(data);
                    angular.forEach(data, function (t) {
                        t.id = $scope.monitoringData.length;
                        t.x = t.date * 1000;
                        t.y = Math.floor(t.value);
                        $scope.monitoringData.add(t);
                    })
                });
            }, 60000);
        };

        $scope.monitoringData = new vis.DataSet();

        $scope.reloadGraph("memfree");

        $scope.rtt_metric = [];
        $scope.packet_loss = [];
        $scope.response_time = [];
        $scope.rtt_metric.push();

        mDataService.get($stateParams.id).then(function (data) {
            $scope.mData = data;
        });
        $scope.mem_percent = 40;
        var promise_table = $interval(function () {
            $scope.cpu_percent = Math.floor((Math.random() * $scope.cpu_percent) + 20);
            var init = Math.floor((Math.random() * 2));
            init *= Math.floor(Math.random() * 2) == 1 ? 1 : -1;
            $scope.mem_percent = $scope.mem_percent + init;
            var rtt = Math.floor((Math.random() * 100) + 1); //ms

            var second; // = $scope.rtt_metric[$scope.rtt_metric.length-1].second +1;
            second = vis.moment();
            $scope.rtt_metric.push({
                x: second,
                y: Math.floor((Math.random() * 100) + 1)
            });
            $scope.packet_loss.push({
                x: second,
                y: Math.floor((Math.random() * 100) + 1)
            });
            $scope.response_time.push({
                x: second,
                y: Math.floor((Math.random() * 100) + 1)
            });
            var packet_loss = Math.floor((Math.random() * 100) + 1); //%
            var response_time = Math.floor((Math.random() * 100) + 1); //ms

        }, 2000);
        $scope.options = {

        };

        $scope.showGraph = function (type) {
            $interval.cancel(promise);
            $scope.graph_name = type;
            $scope.monitoringData.clear();
            promise = $interval(function () {
                if (type == "Round Trip Time") $scope.data = $scope.rtt_metric;
                if (type == "Packet loss") $scope.data = $scope.packet_loss;
                if (type == "Response time") $scope.data = $scope.response_time;
                var second = $scope.monitoringData.length + 1;
                var metric1 = Math.round(Math.random() * 100);
                $scope.monitoringData.add($scope.data[$scope.data.length - 1]);
            }, 2000);
        };

        $scope.graph_name = "";
        $scope.monitoringData = new vis.DataSet()

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
            if (promise_table) {
                $interval.cancel(promise_table);
            }
        });
    });
