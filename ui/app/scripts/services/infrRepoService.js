'use strict';

services
    .factory('infrRepoService', function ($http) {
        return {
            get: function (infr_repo_url, path) {
                var promise = $http.get("rest/api/" + path, {
                    headers: {
                        'Accept': 'application/occi+json',
                        "X-host": infr_repo_url
                    }
                }).then(function (response) {
                    console.log(response);
                    return response.data;
                }, function (response) {});
                return promise;
            }
        };
    });
