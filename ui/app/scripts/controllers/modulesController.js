'use strict';

angular.module('tNovaApp')
    .controller('modulesController', function ($scope, $filter, tenorService, $interval, $modal) {

        $scope.updateModulesList = function () {
            tenorService.get("configs/services").then(function (data) {
                if (data === undefined) return;
                $scope.modulesCollection = data;
            });
        }

        $scope.updateModulesList();
        var promise = $interval(function () {
            $scope.updateModulesList
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
            tenorService.delete("configs/services?name=" + id).then(function (data) {});
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
            tenorService.post("configs/registerService", JSON.stringify(service)).then(function (data) {});
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
        var url = "_cat/indices?";
        url = "elastic/*/_stats/store"
        tenorService.get(url).then(function (data) {
            if (!data) return;
            var indices = Object.keys(data.indices);
            angular.forEach(indices, function (index) {
                $scope.timelineLog(index);
            });
        });

        $scope.timelineLog = function (data) {
            //console.log(data);
            var url = "elastic/" + data + "/_search?pretty=1&q=*&size=50";
            //url = "logstash-2016.01.27/_search?q=module:vnf-catalogue";
            //url = "logstash-2016.01.27/_search";
            tenorService.get(url).then(function (data) {
                if (!data) return;
                //console.log(data.hits.hits);
                //$scope.timeLine.concat( data.hits.hits);
                $scope.log = $scope.log.concat(data.hits.hits);
                angular.forEach(data.hits.hits, function (element) {
                    $scope.data.items.add({
                        id: element.id,
                        content: element._source.module + " - " + element._source.message,
                        start: new Date(element._source['@timestamp']).getTime(),
                        type: 'point'
                    });
                })
            });
        };
        $scope.selectedSeverity = "";
        $scope.log = [];

        $scope.severities = ["ERROR", "DEBUG", "INFO"];

        $scope.selectSeverity = function (severity) {
            $scope.data.items.clear();
            console.log($scope.selectedSeverity);
            url = "elastic/_search?pretty=1&size=200&q=severity:" + $scope.selectedSeverity;
            tenorService.get(url).then(function (data) {
                $scope.log = data.hits.hits;
                if (!data) return;
                angular.forEach(data.hits.hits, function (element) {
                    $scope.data.items.add({
                        id: element.id,
                        content: element._source.module + " - " + element._source.message,
                        start: new Date(element._source['@timestamp']).getTime(),
                        type: 'point'
                    });
                });
            });
        };
    });
