'use strict';

services.factory('genericService', function ($http) {
    return {
        get: function (ip, url) {
            var promise = $http.get("rest/api/" + url, {
                headers: {
                    "X-host": ip
                }
            }).then(function (response) {
                return response.data;
            }, function (response) {});
            return promise;
        }
    };
});
