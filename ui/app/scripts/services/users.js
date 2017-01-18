'use strict';

angular.module('tNovaApp')
    .factory('UsersService', function ($http, $window, $q, AUTHENTICATION) {

        var getUsers = function () {
            var url = AUTHENTICATION + 'users';
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

        var activeUser = function (user_id) {
            var url = AUTHENTICATION + 'users/' + user_id + '/activate';
            var deferred = $q.defer();

            var promise = $http.post(url, {}).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        var disableUser = function (user_id) {
            var url = AUTHENTICATION + 'users/' + user_id + '/disable';
            var deferred = $q.defer();

            var promise = $http.post(url, {}).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        var getProfile = function (user_id) {
            var url = AUTHENTICATION + 'users/' + user_id;
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

        var updateProfile = function (profile) {
            var url = AUTHENTICATION + 'users/' + profile.id;
            var deferred = $q.defer();

            var promise = $http.put(url, profile).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        // jlferrer:
        // When we create a User from the UI as an admin, we emulate a new registration
        // i.e., the user is created as inactive
        var post = function (username, password, email, fullname, tenant, endpoint) {
            var url = AUTHENTICATION + endpoint;
            var deferred = $q.defer();

            $http.post(url, 'username=' + username + '&password=' + password + '&email=' + email + '&fullname=' + fullname + '&tenant=' + tenant, {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            }).then(
                function (response) {
                    deferred.resolve(true);
                },
                function (response) {
                    console.log(response);
                    deferred.reject(response.data);
                }
            );
            return deferred.promise;
        };


        var remove = function (id) {
            var url = AUTHENTICATION + 'users/' + id;
            var deferred = $q.defer();

            var promise = $http.delete(url).then(
                function (response) {
                    return response.data;
                },
                function (response) {
                    deferred.reject(response.data);
                }
            );
            return promise;
        };

        return {
            getUsers: function () {
                return getUsers();
            },
            activeUser: function (user_id) {
                return activeUser(user_id);
            },
            disableUser: function (user_id) {
                return disableUser(user_id);
            },
            getProfile: function (user_id) {
                return getProfile(user_id);
            },
            updateProfile: function (profile) {
                return updateProfile(profile);
            },
            remove: function (user_id) {
                return remove(user_id);
            },
            register: function (username, password, email, fullname, tenant) {
                return post(username, password, email, fullname, tenant, 'register');
            }
        };

    });
