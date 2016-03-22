'use strict';
angular.module('tNovaApp')
    .directive('layers', function ($parse, $window, localStorageService, $timeout) {
        return {
            templateUrl: 'partials/t-nova/popLayers.html',
            scope: {
                yourDirective: '='
            },
            link: function (scope, iElm, iAttrs, controller) {
                $timeout(function () {
                    console.log(scope.yourDirective);
                });
                scope.$on('rootElements', function (events, ntdata) {
                    if (ntdata) {
                        scope.rootElement = ntdata;
                    }
                });
            }
        };
    });
