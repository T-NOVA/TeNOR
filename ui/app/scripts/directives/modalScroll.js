'use strict';
angular.module('tNovaApp')
    .directive('modalscroll', function ($window) {
        return {
            priority: 0,
            link: function (scope, element) {
                var i = 0;
                scope.$watch(function () {
                    return $(element).height();
                }, function (newValue, oldValue) {
                    var windowElement = angular.element($window);
                    var scrollHeight = element[0].scrollHeight;
                    if (scrollHeight + 180 > windowElement.height()) {
                        console.log("Set bigger");
                        element.css('height', windowElement.height() - 220);
                    } else {
                        console.log("Set small");
                        if(scrollHeight == 22) element.css('height', windowElement.height() - 200);
                        else element.css('height', scrollHeight);
                    }
                });
            }
        }
    }).directive('modalscrollupload', function ($window) {
        return {
            priority: 0,
            link: function (scope, element) {
                var i = 0;
                scope.$watch(function () {
                    return $(element).height();
                }, function (newValue, oldValue) {
                    var windowElement = angular.element($window);
                    var scrollHeight = element[0].scrollHeight;
                    if (scrollHeight + 180 < windowElement.height()) {
                        console.log("Set bigger");
                        element.css('height', windowElement.height() - 220);
                    } else {
                        console.log("Set small");
                        if(scrollHeight == 22) element.css('height', windowElement.height() - 200);
                        else element.css('height', scrollHeight);
                    }
                });
            }
        }
    }).directive('dynamicHeight', function () {
    return {
        restrict: 'A',
        link: function (scope, elm, attrs) {
            var parent = elm.parent();

            scope.$watch(function () {
                return {
                    height: parent.prop('offsetHeight'),
                    width: parent.prop('offsetWidth')
                };
            }, function (size) {
                console.log(size);
                if (size.height > 390) elm.parent().css('height', 400);
            }, true);
        }
    };
});;
