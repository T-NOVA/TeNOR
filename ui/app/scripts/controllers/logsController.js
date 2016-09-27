'use strict';

angular.module('tNovaApp')
    .controller('logsController', function ($scope, $filter, tenorService, $interval, $modal) {

        $scope.log = [];
        $scope.severities = ["ERROR", "DEBUG", "INFO"];
        $scope.modules = ["ns_manager", "ns_catalogue", "ns_provisioning", "ns_monitoring", "vnf_manager", "vnf_catalogue", "vnf_provisioner", "vnf_monitoring", "hot_generator"];
        $scope.days = [];
        $scope.selectedDay = "";
        $scope.selectedSeverity = "ERROR";
        $scope.selectedModule = "";
        var url = "elastic/*/_stats/store"
        tenorService.get(url).then(function (data) {
            if (!data) return;
            var indices = Object.keys(data.indices);
            indices = _.sortBy(indices, function (name) {
                return name
            }).reverse();
            console.log(indices);
            angular.forEach(indices, function (index) {
                $scope.days.push(index);
            });
        });

        $scope.getLogs = function (day) {
            $scope.selectedDay = day;
            var url = "elastic/" + $scope.selectedDay + "/_search?pretty=1&q=*&size=2000&q=severity:" + $scope.selectedSeverity;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data.hits.hits;
            });
        }

        $scope.getBySeverity = function (severity) {
            var url = "elastic/" + $scope.selectedDay + "/_search?pretty=1&q=*&size=2000&q=severity:" + $scope.selectedSeverity;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data.hits.hits;
            });
        };

        $scope.getByModule = function (module) {
            var url = "elastic/" + $scope.selectedDay + "/_search?pretty=1&size=2000&q=module:" + $scope.selectedModule;
            console.log(url)
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data.hits.hits;
            });
        };
    });
