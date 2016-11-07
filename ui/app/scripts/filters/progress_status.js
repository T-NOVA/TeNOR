'use strict';

angular.module('tNovaApp')
.filter('progress', function ($filter) {

    return function (item, filterOn) {
        var status = [
              {id: "INIT", progress: "10"},
              {id: "MAPPED FOUND", progress: "20"},
              {id: "NETWORK CREATED", progress: "30"},
              {id: "INSTANTIATING VNFs", progress: "60"},
              {id: "INSTANTIATED", progress: "100"},
              {id: "START", progress: "100"},
              {id: "DELETING", progress: "50"}
      ];
      var t = $filter('filter')(status, {id: item})[0];
      return t.progress;
          };
      });
