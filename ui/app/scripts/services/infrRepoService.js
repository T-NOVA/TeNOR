'use strict';

services
    .factory('infrRepoService', function ($http) {
        return {
            get: function (infr_repo_url, path) {
                console.log(infr_repo_url);
                var promise = $http.get("rest/api/" + path, {
                    headers: {
                        'Accept': 'application/occi+json',
                        "X-host": infr_repo_url
                    }
                }).then(function (response) {
                    console.log(response);
                    console.log(response.data);
                    return response.data;
                }, function (response) {});
                return promise;
            }
        };
    });
