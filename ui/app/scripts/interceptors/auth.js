'use strict';

angular.module('tNovaApp')
    .factory('AuthInterceptor', function ($rootScope, $q, $window, $location) {
        return {
            request: function (config) {
                config.headers = config.headers || {};
                if ($window.localStorage.token) {
                    config.headers.Authorization = 'Token ' + $window.localStorage.token;
                    //$location.path('/dashboard');
                }
                //$location.path('/dashboard');
                return config;
            },

            responseError: function (response) {
                if (response.status === 401) {
                    $window.localStorage.removeItem('token');
                    $window.localStorage.removeItem('username');
                    $location.path('/login');
                    return;
                }
                return $q.reject(response);
            }
        };
    });
