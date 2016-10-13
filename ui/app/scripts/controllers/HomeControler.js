'use strict';

angular.module('tNovaApp')
    .controller('HomeController', function ($scope, tenorService) {

        $scope.nsSize = $scope.vnfSize = $scope.instancesSize = 0;

        tenorService.get('network-services').then(function (data) {
            if (data !== undefined) $scope.nsSize = data.length;
        });
        tenorService.get('vnfs').then(function (data) {
            if (data !== undefined) $scope.vnfSize = data.length;
        });
        tenorService.get("ns-instances").then(function (data) {
            if (data !== undefined) $scope.instancesSize = data.length;
        });

        $scope.summaryData = {};
        $scope.summaryData.ns_created_requests = 0;
        $scope.summaryData.ns_instantiated_requests = 0;
        $scope.summaryData.ns_terminated_requests = 0;
        $scope.summaryData.ns_updated_requests = 0;
        $scope.summaryData.vnf_created_requests = 0;
        $scope.summaryData.ns_scaling_requests = 0;
        $scope.summaryData.ns_scaling_actions = 0;
        $scope.summaryData.SLA_breaches = 0;
        $scope.summaryData.SM_request = 0;
        $scope.summaryData.SM_rate = 0;
        $scope.summaryData.SM_execution_time = 0;
        //Summary monitoring data
        tenorService.get('statistics/generic').then(function (data) {
            if (data) {
                data.forEach(function (d) {
                    $scope.summaryData[d.name] = d.value;
                });
            }
        });

        $scope.reset = function (id) {
            $scope.summaryData[id] = 0;
            // tenorService.put('statistics/'+ 1, $scope.summaryData).then(function (data) {});
        };

        $scope.info = function (id) {
            //show tooltop -> http://mgcrea.github.io/angular-strap/#/page-one#tooltips
        };

        $scope.tooltipUrl = "bower_components/angular-strap/src/tooltip/tooltip.tpl.html";
        $scope.ns_created = {
            "title": "Measures the number of NS creation requests."
        };
        $scope.ns_instantiated = {
            "title": "Measures the number of NS instantiation requests."
        };
        $scope.ns_terminated = {
            "title": "Measures the number of NS termination requests."
        };
        $scope.ns_updated = {
            "title": "Measures the number of update NS requests received."
        };
        $scope.vnf_created = {
            "title": "Measures the number of create VNF requests received from the NF Store."
        };
        $scope.ns_scaling_requests = {
            "title": "Provides information on the number of manually triggered NS Scaling requests have been received."
        };
        $scope.ns_scaling_actions = {
            "title": "Provides information on the number of automatically triggered NS Scaling requests within the orchestrator."
        };
        $scope.SLA_breaches = {
            "title": "Provides information on the number of SLA breaches measured by the SLA enforcement module of the orchestrator."
        };
        $scope.SM_request = {
            "title": "Number of service mapping requests performed to the algorithm."
        };
        $scope.SM_rate = {
            "title": "Percentage of the successful mapping requests completed."
        };
        $scope.SM_execution_time = {
            "title": "The average execution time of a mapping request."
        };

        $scope.lastLogs = function () {
            $scope.fromDate = Date.now() + -1*24*3600*1000;
            $scope.untilDate = Date.now();
            var url = "logs/?module=ns_provisioner&severity=INFO&from=" + new Date($scope.fromDate).getTime()/1000 + "&until=" + new Date($scope.untilDate).getTime()/1000;
            tenorService.get(url).then(function (data) {
                if (!data) return;
                $scope.lastHistory = data.slice(0,20);
            });
        };

        $scope.lastLogs();
    });
