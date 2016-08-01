'use strict';

angular.module('tNovaApp.directives', [])
    .directive('fullHeight', function ($window) {
        return {
            restrict: 'A',
            link: function (scope, element, attrs) {
                var offsetHeight = attrs.offset | 0;
                element.css('min-height', ($window.innerHeight - 35) + 'px');
                // handle resize, fix footer position. Now only support fixed mode
                angular.element($window).bind('resize', function (e) {
                    element.css('min-height', (e.target.innerHeight - 35) + 'px');
                });
            }
        };
    });
