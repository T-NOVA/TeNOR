'use strict';

angular.module('tNovaApp')
    .directive('visGraph2d', function () {
    return {
        restrict: 'EA',
        transclude: false,
        scope: {
            data: '=',
            options: '=',
            events: '='
        },
        link: function (scope, element, attr) {
            var graphEvents = [
                'rangechange',
                'rangechanged',
                'timechange',
                'timechanged',
                'finishedRedraw'
            ];

            // Create the chart
            var graph = null;

            scope.$watch('data', function () {
                // Sanity check
                if (scope.data == null) {
                    return;
                }

                // If we've actually changed the data set, then recreate the graph
                // We can always update the data by adding more data to the existing data set
                if (graph != null) {
                    graph.destroy();
                }

                // Create the graph2d object
                graph = new vis.Graph2d(element[0], scope.data.items, scope.data.groups, scope.options);

                // Attach an event handler if defined
                angular.forEach(scope.events, function (callback, event) {
                    if (graphEvents.indexOf(String(event)) >= 0) {
                        graph.on(event, callback);
                    }
                });

                // onLoad callback
                if (scope.events != null && scope.events.onload != null &&
                    angular.isFunction(scope.events.onload)) {
                    scope.events.onload(graph);
                }
            });

            scope.$watchCollection('options', function (options) {
                if (graph == null) {
                    return;
                }
                graph.setOptions(options);
            });
        }
    };
});