'use strict';

angular.module('tNovaApp')
    .factory('ProfileService', function ($http, $window, $q, AUTHENTICATION) {

        var get = function () {
            var url = AUTHENTICATION + 'profile';
            var deferred = $q.defer();

            var promise = $http.get(url, {}).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        var put = function (data) {
            var url = AUTHENTICATION + 'profile';
            var deferred = $q.defer();

            var promise = $http.put(url, data).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        var putPass = function (old_password, password, re_password) {
            var url = AUTHENTICATION + 'profile/pass';
            //var deferred = $q.defer();

            var promise = $http.put(url, {
                'old_password': old_password,
                'password': password,
                're_password': re_password
            }).then(
                function (response) {
                    console.log(response);
                    if (response.status === 400) return $q.reject(response.data);
                },
                function (response) {
                    //deferred.reject(response.data);
                    return $q.reject(response.data);
                }
            );
            return promise;
        };

        return {
            getProfile: function () {
                return get();
            },
            updateProfile: function (data) {
                return put(data);
            },
            updatePass: function (old_password, password, re_password) {
                return putPass(old_password, password, re_password);
            }
        };

    });
