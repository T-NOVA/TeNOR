'use strict';

services.factory('tenorService', function ($http, TENOR) {
    return {
        get2: function (url) {
            return $http.get("rest/api/" + url, {
                headers: {
                    "X-host": TENOR
                }
            });
        },
        get: function (url) {
            var promise = $http.get("rest/api/" + url, {
                headers: {
                    "X-host": TENOR
                }
            }).then(function (response) {
                return response.data;
            }, function (response) {});
            return promise;
        },
        post: function (url, data) {
            console.log(data)
            var promise = $http.post("rest/api/" + url, data, {
                headers: {
                    "X-host": TENOR,
                    "Content-Type": "application/json"
                }
            }).then(function (response) {
                console.log(response);
                return response.data;
            }, function (response) {});
            return promise;
        },
        put: function (url, data) {
            var promise = $http.put("rest/api/" + url, data, {
                headers: {
                    "X-host": TENOR
                }
            }).then(function (response) {
                return response.data;
            }, function (response) {});
            return promise;
        },
        delete: function (url) {
            var promise = $http.delete("rest/api/" + url, {
                headers: {
                    "X-host": TENOR
                }
            }).then(function (response) {
                return response.data;
            }, function (response) {});
            return promise;
        }
    };
});
