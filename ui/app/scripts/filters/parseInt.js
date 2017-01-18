'use strict';

angular.module('tNovaApp')
  .filter('parseInt', function() {
    return function(input) {
      return parseInt(input, 10);
    };
})
