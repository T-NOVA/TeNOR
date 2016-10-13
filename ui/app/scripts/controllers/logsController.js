'use strict';

angular.module('tNovaApp')
    .controller('logsController', function ($scope, $filter, tenorService, $interval, $modal) {

        $scope.log = [];
        $scope.severities = ["ERROR", "DEBUG", "INFO", "WARN"];
        $scope.modules = ["ns_manager", "ns_catalogue", "ns_provisioner", "ns_monitoring", "nsd_validator", "vnf_manager", "vnf_catalogue", "vnf_provisioner", "vnf_monitoring", "hot_generator", "vnfd_validator"];
        $scope.days = [];
        $scope.selectedDay = "";
        $scope.selectedSeverity = "ERROR";
        $scope.selectedModule = undefined;
        $scope.fromDate = Date.now() + -1*24*3600*1000;
        $scope.untilDate = Date.now();

        $scope.getLogs = function () {
            var url;
            if ($scope.selectedModule === undefined)
                url = "logs/?severity=" + $scope.selectedSeverity + "&from=" + new Date($scope.fromDate).getTime()/1000 + "&until=" + new Date($scope.untilDate).getTime()/1000;
            else
                url = "logs/?module=" + $scope.selectedModule + "&severity=" + $scope.selectedSeverity + "&from=" + new Date($scope.fromDate).getTime()/1000 + "&until=" + new Date($scope.untilDate).getTime()/1000;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.log = data;
            });
        };
    });
