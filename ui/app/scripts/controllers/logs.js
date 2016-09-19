'use strict';

angular.module('tNovaApp')
    .controller('logsController', function ($scope, $filter, tenorService, $interval, $modal) {

        $scope.log = [];
        $scope.severities = ["ERROR", "DEBUG", "INFO"];
        $scope.days = [];
        $scope.selectedDay = "";
        $scope.selectedSeverity = "ERROR";
        var url = "elastic/*/_stats/store"
        tenorService.get(url).then(function (data) {
            if (!data) return;
            var indices = Object.keys(data.indices);
            console.log(indices);
            angular.forEach(indices, function (index) {
                $scope.days.push(index);
            });
        });

        $scope.getLogs = function (day) {
            var url = "elastic/" + $scope.selectedDay + "/_search?pretty=1&q=*&size=200&q=severity:" + $scope.selectedSeverity;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data.hits.hits;
            });
        }

        $scope.selectSeverity = function (severity) {
            console.log($scope.selectedSeverity);
            var url = "elastic/" + $scope.selectedDay + "/_search?pretty=1&q=*&size=200&q=severity:" + $scope.selectedSeverity;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data.hits.hits;
            });
        };
    });
