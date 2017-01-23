'use strict';

angular.module('tNovaApp')
    .directive('timeLine', function () {
        return {
            restrict: 'EA',
            transclude: false, //
            // require: '^ngModel',
            /*
            scope: {
                ngModel: '=',
                onSelect: '&',
                options: '='
            },*/
            scope: {
                data: '=',
                options: '=',
                events: '='
            },
            link: function (scope, element, attr) {
                var timeline = null;
                scope.$watch('data', function () {
                    // Sanity check
                    if (scope.data == null) {
                        return;
                    }

                    // If we've actually changed the data set, then recreate the graph
                    // We can always update the data by adding more data to the existing data set
                    if (timeline != null) {
                        timeline.destroy();
                    }

                    // Create the graph2d object
                    //                    timeline = new vis.Graph2d(element[0], scope.data.items, scope.data.groups, scope.options);
                    timeline = new vis.Timeline(element[0], scope.data.items, scope.options);

                    // Attach an event handler if defined
                    angular.forEach(scope.events, function (callback, event) {
                        if (graphEvents.indexOf(String(event)) >= 0) {
                            timeline.on(event, callback);
                        }
                    });

                    // onLoad callback
                    if (scope.events != null && scope.events.onload != null &&
                        angular.isFunction(scope.events.onload)) {
                        scope.events.onload(timeline);
                    }
                });


                scope.$watchCollection('options', function (options) {
                    if (timeline == null) {
                        return;
                    }
                    timeline.setOptions(options);
                });

                /*
                    $scope.$watch('ngModel', function (newValue, oldValue) {
                    console.log("Updating...")
                    var items = [];
                    _.each($scope.ngModel, function (element, index) {
                        console.log(element);
                        items.push({
                            id: element.id,
                            //content: element._source.message,
                            content: element._source.module,
                            start: new Date(element._source['@timestamp']).getTime()
                        });
                    })

                    var options = {
                        start: new Date($scope.ngModel[$scope.ngModel.length - 1]._source['@timestamp']),
                        zoomMin: 1000, // a day
                        zoomMax: 1000 * 60 * 60 * 24 * 30 * 3 // three months
                    };
                    var timeline = new vis.Timeline($element[0], items, options);
                });

                $scope.$watch('ngModel', function (newValue, oldValue) {
                    if (newValue) {
                        var items = [];
                        _.each($scope.ngModel, function (element, index) {
                            console.log(element);
                            items.push({
                                id: element.id,
                                //content: element._source.message,
                                content: element._source.module,
                                start: new Date(element._source['@timestamp']).getTime()
                            });
                        })

                        var options = {
                            start: new Date($scope.ngModel[$scope.ngModel.length - 1]._source['@timestamp']),
                            zoomMin: 1000, // a day
                            zoomMax: 1000 * 60 * 60 * 24 * 30 * 3 // three months
                        };
                        var timeline = new vis.Timeline($element[0], items, options);
                    }
                });*/
            }
        }
    });
