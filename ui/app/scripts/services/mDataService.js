'use strict';

services.factory('mDataService', function ($http) {
    return {
        list: function () {
            var promise = $http.get("rest/mData").then(function (response) {
                return response.data;
            }, function (response) {

            });
            return promise;
        },
        get: function (id) {
            var promise = $http.get("rest/mData/" + id).then(function (response) {
                return response.data;
            }, function (response) {

            });
            return promise;
        }
    };
});
