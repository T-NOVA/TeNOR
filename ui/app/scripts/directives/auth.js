'use strict';

angular.module('tNovaApp')
    .directive('restrict', function ($window) {
        return {
            restrict: 'A',
            prioriry: 100000,
            scope: false,
            link: function () {
                // alert('ergo sum!');
            },
            compile: function (element, attr) {
                var accessDenied = true;
                //var user = AuthService.getUser();
                //if(attr.access)
                //var t = attr.access.includes(' ');
                console.log(attr.access);
                //if (attr.access.includes(' ')) {
                if (typeof attr.access.includes == 'function') {
                    if (attr.access.includes(' ')) {
                        var attributes = attr.access.split(' ');
                    } else {
                        var attributes = [attr.access];
                    }
                } else {
                    if (attr.access.contains(' ')) {
                        var attributes = attr.access.split(' ');
                    } else {
                        var attributes = [attr.access];
                    }
                }

                if ($window.localStorage.userRoles === undefined) return
                if (typeof attr.access.includes == 'function') {
                    if ($window.localStorage.userRoles.includes(' ')) var roles = $window.localStorage.userRoles.split(' ');
                } else {
                    if ($window.localStorage.userRoles.contains(' ')) var roles = $window.localStorage.userRoles.split(' ');
                }
                for (var i in attributes) {
                    for (var j in roles) {
                        if (roles[j] === attributes[i]) {
                            accessDenied = false;
                        }
                    }
                }

                if (accessDenied) {
                    element.children().remove();
                    element.remove();
                }
            }
        };
    });
