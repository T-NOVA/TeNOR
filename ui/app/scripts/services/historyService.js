'use strict';

services.factory('HistoryService', function ($resource) {
    return $resource('rest/history/:id', {id: '@id'});
});
