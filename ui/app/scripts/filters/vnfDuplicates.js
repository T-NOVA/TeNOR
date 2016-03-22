'use strict';

angular.module('tNovaApp')
        .filter('vnfDuplicates', function () {

            return function (items, filterOn) {
                if ((filterOn || angular.isUndefined(filterOn)) && angular.isArray(items)) {
                    var newItems = [];

                    angular.forEach(items, function (item) {
                        var isDuplicate = false;
                        for (var i = 0; i < filterOn.length; i++) {
                            if (angular.equals(item, filterOn[i])) {
                                isDuplicate = true;
                                break;
                            }
                        }
                        
                        if (!isDuplicate) {
                            newItems.push(item);
                        }

                    });
                    items = newItems;
                }
                return items;
            };
        });