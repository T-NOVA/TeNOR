'use strict';

services
    .factory('infrRepoService', function ($http, REPOSITORY) {
        return {
            get: function (url) {
                var promise = $http.get("rest/api/" + url, {
                    headers: {
                        'Accept': 'application/occi+json',
                        "X-host": REPOSITORY
                    }
                }).then(function (response) {
                    return response.data;
                }, function (response) {});
                return promise;
            }
        };
    });
