'use strict';

angular.module('tNovaApp')
    .controller('HistoryListController', function ($scope, HistoryService, $filter) {

        var data = HistoryService.query({}, function (result) {
            $scope.dataCollection = result;
        });
    })
    .controller('HistoryCreateController', function ($scope, HistoryService) {
        $scope.history = new HistoryService();

        $scope.types = [
                'INFO',
                'ERROR',
                'WARN'
            ];

        $scope.history.type = $scope.types[0]; // info

        $scope.save = function () {
            $scope.history.content = "Dummy Hist entry";
            $scope.history.$save(function (data) {
                console.log(data);
            });
        };
    });
