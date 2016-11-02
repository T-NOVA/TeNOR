'use strict';

angular.module('tNovaApp')
    .controller('vnfController', function ($scope, $stateParams, $filter, tenorService, $interval, $modal) {

        $scope.descriptor = {};
        var page_num = 20;
        var page = 1;
        $scope.dataCollection = [];
        $scope.getVnfList = function (page) {
            tenorService.get('vnfs?offset=' + page + '&limit=' + page_num).then(function (data) {
                if (data.length > 0) {
                    $scope.dataCollection = _.sortBy($scope.dataCollection.concat(data), function (o) {
                        var dt = new Date(o.created_at);
                        return -dt;
                    });
                    page++;
                    $scope.getVnfList(page);
                }
            });
        };

        $scope.getVnfList(page);
        var promise = $interval(function () {
            $scope.dataCollection = [];
            $scope.getVnfList(page);
        }, 1000000);

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
                $scope.getVnfList(page);
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

        $scope.uploadDialog = function(){
            $modal({
                title: "Upload a VNFD",
                template: "views/t-nova/modals/upload.html",
                show: true,
                scope: $scope,
            });
        }

        $scope.uploadFile = function(files){
            var fd = new FormData();
            //Take the first selected file
            fd.append('file', files[0]);
            var obj = JSON.parse(files);
            console.log(obj);
            tenorService.post('vnfs', obj).then(function (data) {
                console.log(data);
                $scope.getVnfList(page);
            });
            this.$hide();
        }

        $scope.loadFile = function (element) {
            var file = element.files[0];
            var reader = new FileReader();
            reader.onload = function () { //event waits the file content
                $scope.$apply(function () {
                    $scope.descriptor = JSON.stringify(JSON.parse(reader.result), undefined, 4); //JSON.parse(reader.result);
                });
            };
            reader.readAsText(file);
        };

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
                $scope.dataCollection = _.sortBy(data, function (o) {
                    var dt = new Date(o.created_at);
                    return -dt;
                });
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
    .controller('vnfMonitoringController', function ($scope, $stateParams, $filter, mDataService, $interval, tenorService, $timeout) {
        var promise, promise1, promise2;
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
                                vdu: vdu['id'],
                                type: m.desc,
                                value: 0,
                                valueType: m.metric
                            });
                        });
                        vdu.monitoring_parameters_specific.forEach(function (m) {
                            $scope.tableData.push({
                                vdu: vdu['id'],
                                type: m.desc,
                                value: 0,
                                valueType: m.metric
                            });
                        });
                    });
                });
            });
        };

        $scope.oldType = "";
        $scope.reloadGraph = function (type) {
            $interval.cancel(promise1);
            $interval.cancel(promise2);
            $scope.monitoringData.clear();
            $scope.newType = type;
            if ($scope.oldType !== type) {
                $scope.oldType = type;
            }
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
                url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type + "&end=" + lastEndDate;
                tenorService.get(url).then(function (data) {
                    if (data.length == 0) {
                        $interval.cancel(promise1);
                        return
                    }
                    _.each(data, function (t) {
                        t['x'] = t.date * 1000;
                        t['y'] = parseFloat(t.value);
                    });
                    $scope.monitoringData.add(data);
                    lastEndDate = data[data.length - 1].date - 1;
                });
            }, historicInterval);
            promise2 = $interval(function () {
                url = "instances/" + $stateParams.id + "/monitoring-data/?instance_type=vnf&metric=" + type + "&start=" + lastStartDate;
                tenorService.get(url).then(function (data) {
                    if (data.length == 0) return
                    _.each(data, function (t) {
                        t['x'] = t.date * 1000;
                        t['y'] = parseFloat(t.value);
                    });
                    $scope.monitoringData.add(data);
                    lastStartDate = data[data.length - 1].date;
                });
            }, realTimeInterval);
        };

        $scope.graph_name = "";
        $scope.monitoringData = new vis.DataSet();

        $scope.options = {

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
            if (promise_table) {
                $interval.cancel(promise_table);
            }
        });
    });
