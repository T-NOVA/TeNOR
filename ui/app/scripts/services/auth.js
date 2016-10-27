'use strict';

angular.module('tNovaApp')
    .factory('AuthService', function ($http, $window, $q, TENOR) {

        var login = function (obj) {
            var url = 'rest/api/auth/login';
            var deferred = $q.defer();

            $http.post(url, obj, {
                headers: {
                    "X-host": TENOR,
                    "Content-Type": "application/json"
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

        var profile = function(user_id, token){
            var url = 'rest/gk/api/admin/user/' + user_id;
            var deferred = $q.defer();

            $http.get(url, {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Auth-Token': token,
                    'X-host': TENOR
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

        var loginGK = function (user_id, password) {
            var url = 'rest/gk/api/token/';
            var deferred = $q.defer();

            $http.post(url, '', {
                headers: {
                    'Content-Type': 'application/json',
                    'X-Auth-Password': password,
                    'X-Auth-Uid': user_id,
                    "X-host": BACKEND
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
                    'X-host': BACKEND
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

        var logout = function (token) {
            var deferred = $q.defer();
            var url = 'rest/api/auth/logout';
            $http.post(url, {}, {
                headers: {
                    'X-host': TENOR,
                    'X-Auth-Token': token
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
                    deferred.reject(response.data);
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
                    'X-host': BACKEND
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

        var post = function (token, path, object) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/' + path;
            $http.post(url, object, {
                headers: {
                    'X-Auth-Token': token,
                    'X-host': BACKEND
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

        var remove = function (token, path) {
            var deferred = $q.defer();
            var url = 'rest/gk/api/' + path;
            console.log(url);
            var promise = $http.delete(url, {
                headers: {
                    'X-Auth-Token': token,
                    'X-host': BACKEND
                }
            }).then(
                function (response) {
                    console.log(response);
                }
            );
            return promise;
        };

        return {
            logout: function (token_id) {
                return logout(token_id);
            },
            login: function (obj) {
                return login(obj);
            },
            profile: function (user_id, token) {
                return profile(user_id, token);
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
