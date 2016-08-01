'use strict';

angular.module('tNovaApp')
    .factory('AuthService', function ($http, $window, $q, BACKEND, AUTHENTICATION) {

        var loginGK = function (user_id, password) {
            var url = 'rest/gk/api/token/';
            var deferred = $q.defer();

            $http.post(url, '', {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Auth-Password': password,
                    'X-Auth-Uid': user_id,
                    "X-host": AUTHENTICATION
                }
            }).then(
                function (response) {
                    console.log(response);
                    //$window.localStorage.userId = userId;
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.reject(response.data);
                }
            );
            return deferred.promise;
        };

        var profileGK = function (user_id, token) {
            var url = 'rest/gk/api/admin/user/' + user_id;
            var deferred = $q.defer();

            $http.get(url, {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Auth-Token': token,
                    'X-host': AUTHENTICATION
                }
            }).then(
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.reject(response.data);
                }
            );
            return deferred.promise;
        };

        var logout = function (token_id) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/token/' + token_id;
            $http.delete(url, {
                headers: {
                    'X-host': AUTHENTICATION
                }
            }).then(
                function (response) {
                    $window.localStorage.removeItem('token');
                    $window.localStorage.removeItem('username');
                    console.log(response);
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                }
            );
            return deferred.promise;
        };

        var get = function (token, path) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/' + path;
            $http.get(url, {
                headers: {
                    'X-Auth-Token': token,
                    'X-host': AUTHENTICATION
                }
            }).then(
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                }
            );
            return deferred.promise;
        };

        var post = function (token, path) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/' + path;
            $http.delete(url, {
                headers: {
                    'X-Auth-Token': token,
                    'X-host': AUTHENTICATION
                }
            }).then(
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                }
            );
            return deferred.promise;
        };

        var remove = function (token, path, object) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/' + path;
            $http.post(url, object, {
                headers: {
                    'X-Auth-Token': token,
                    'X-host': AUTHENTICATION
                }
            }).then(
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                },
                function (response) {
                    console.log(response);
                    deferred.resolve(response.data);
                }
            );
            return deferred.promise;
        };

        return {
            logout: function (token_id) {
                return logout(token_id);
            },
            loginGK: function (user_id, password) {
                return loginGK(user_id, password);
            },
            profileGK: function (user_id, token) {
                return profileGK(user_id, token);
            },
            get: function (token, path) {
                return get(token, path);
            },
            post: function (token, path, object) {
                return post(token, path, object);
            },
            delete: function (token, path) {
                return remove(token, path);
            }
        };

    });
