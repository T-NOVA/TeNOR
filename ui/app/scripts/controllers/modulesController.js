'use strict';

angular.module('tNovaApp')
    .controller('modulesController', function ($scope, $filter, tenorService, $interval, $modal) {

        $scope.types_internal_modules = ["", "manager"];
        $scope.types_external_modules = ["mapping", "infr_repo", "mapi", "vim_monitoring"];
        $scope.types_modules = $scope.types_internal_modules.concat($scope.types_external_modules)
        $scope.externalModulesCollection = [];

        $scope.updateModulesList = function () {
            tenorService.get("modules/services").then(function (data) {
                if (data === undefined) return;
                $scope.modulesCollection = data;
            });
        };

        $scope.updateExternalModulesList = function () {
            $scope.types_external_modules.forEach(function(type){
                tenorService.get("modules/services/type/" + type).then(function (data) {
                    if (data === undefined) return;
                    $scope.externalModulesCollection = $scope.externalModulesCollection.concat(data);
                });
            })
        };

        $scope.updateModulesList();
        $scope.updateExternalModulesList();
        var promise = $interval(function () {
            $scope.updateModulesList();
            //$scope.updateExternalModulesList();
        }, defaultTimer);

        $scope.deleteDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                template: "partials/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });
        };
        $scope.deleteItem = function (id) {
            tenorService.delete("modules/services?name=" + id).then(function (data) {});
            this.$hide();
        };

        $scope.$on("$destroy", function () {
            if (promise) {
                $interval.cancel(promise);
            }
        });

        $scope.registerService = function (service) {
            console.log("register service");
            console.log(service);
            service.secret = service.name
            service.depends_on = [];
            tenorService.post("modules/services", JSON.stringify(service)).then(function (data) {
                console.log(data);
            });
        };

        $scope.options = {
            //start: new Date($scope.ngModel[$scope.ngModel.length - 1]._source['@timestamp']),
            start: new Date(),
            zoomMin: 1000, // a day
            zoomMax: 1000 * 60 * 60 * 24 * 30 * 3, // three months,
            height: '300px'
        };
        var items = [];

        /*$scope.data = {
            items: new vis.DataSet(items),
        };*/
        $scope.timeline = [];
        $scope.data = {
            items: new vis.DataSet(items)
        };

        $scope.timeLine = [];

        $scope.log = [];
        $scope.severities = ["ERROR", "DEBUG", "INFO", "WARN"];
        $scope.modules = ["ns_manager", "ns_catalogue", "ns_provisioner", "ns_monitoring", "nsd_validator", "vnf_manager", "vnf_catalogue", "vnf_provisioner", "vnf_monitoring", "hot_generator", "vnfd_validator"];
        $scope.days = [];
        $scope.selectedDay = "";
        $scope.selectedSeverity = "ERROR";
        $scope.selectedModule = undefined;
        $scope.fromDate = Date.now() + -1*24*3600*1000;
        $scope.untilDate = Date.now();
        var url;

        $scope.timelineLog = function (module) {
            //console.log(data);
            url = "logs/?module=" + module + "&severity=" + $scope.selectedSeverity + "&from=" + new Date($scope.fromDate).getTime()/1000 + "&until=" + new Date($scope.untilDate).getTime()/1000;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = $scope.log.concat(data);
                angular.forEach(data, function (element) {
                    //console.log(element);
                    $scope.data.items.add({
                        id: element.id,
                        content: element.module + " - " + element.msg,
                        start: new Date(element.time).getTime(),
                        type: 'point'
                    });
                })
            });
        };

        $scope.log = [];
        angular.forEach($scope.modules, function (module) {
            //$scope.timelineLog(module);
        });

        $scope.selectSeverity = function (severity) {
            $scope.data.items.clear();
            console.log($scope.selectedSeverity);
            url = "logs/?severity=" + $scope.selectedSeverity + "&from=" + new Date($scope.fromDate).getTime()/1000 + "&until=" + new Date($scope.untilDate).getTime()/1000;
            tenorService.get(url).then(function (data) {
                $scope.log = data;
                if (!data) return;
                angular.forEach(data, function (element) {
                    $scope.data.items.add({
                        id: element.id,
                        content: element.module + " - " + element.msg,
                        start: new Date(element.time).getTime(),
                        type: 'point'
                    });
                });
            });
        };
    });
