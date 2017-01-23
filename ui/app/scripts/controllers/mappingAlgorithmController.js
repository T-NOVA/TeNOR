'use strict';

angular.module('tNovaApp')
    .controller('mappingAlgorithmController', function ($scope, tenorService, $loading) {

        var instances = [];
        var mapping_avg = 0;
        var instantiation_avg = 0;
        var total_avg = 0;
        var total_std = 0;

        $scope.scatterData = [];

        var groups = new vis.DataSet();
        groups.add({
            id: 0,
            content: "Time",
            options: {
                style: "points",
                drawPoints: {
                    style: 'circle' // square, circle
                }
            }
        });
        groups.add({
            id: 1,
            content: "Average",
            className: "custom-line-style",
            options: {
                drawPoints: false
            }
        });

        $scope.options = {
            legend: true,
            sort: true,
            sampling: false,
            dataAxis: {
                title: {
                    left: {
                        text: "Instantiation time (ms)"
                    }
                },
                customRange: {
                    left: {},
                    showMinorLabels: true
                },
                left: {
                    format: function (value) {
                        return '' + value.toPrecision();
                    }
                }
            },
            defaultGroup: 'Scatterplot',
            height: '300px'
        };
        var items = [];
        $scope.data = {
            items: new vis.DataSet(items),
            groups: groups
        };

        $scope.monitoringData = [];
        var instantiations = 0;
        var mappings = 0;
        $loading.start('scatter');
        tenorService.get("statistics/performance_stats").then(function (data) {
            $scope.performance_stats = data;
            instances = data;
            var d;
            var k = 0;
            for (var i = 0; i <= instances.length - 1; i++) {
                //for (var i = 0; i <= 10 - 1; i++) {
                d = instances[i];
                d.mapping_time = d.mapping;
                d.instantiation_end_time = d.created_at + d.instantiation;
                d.mapping_time = d.mapping;
                //mapping_avg = mapping_avg + Date.parse(d.mapping_time) - Date.parse(d.created_at);
                if (d.instantiation_end_time) {
                    k++;
                    //instantiation_avg = instantiation_avg + Date.parse(d.instantiation_end_time) - Date.parse(d.instantiation_start_time);
                    instantiation_avg = Math.floor(Math.floor(instantiation_avg) + Math.floor(d.instantiation));
                    total_avg = Math.floor(total_avg + Math.floor(d.instantiation));
                    total_std = Math.floor(total_std + (d.instantiation) ^ 2);

                    $scope.data.items.add({
                        x: Math.floor(d.created_at),
                        y: Math.floor(d.instantiation/1000),
                        group: 0
                    });
                }

                if (i === instances.length - 1) {
                    mapping_avg = mapping_avg / instances.length;
                    instantiation_avg = instantiation_avg / k;
                    total_avg = total_avg / k;
                    total_std = total_std / k;
                    $loading.finish('scatter');
                    var averageValues = 0;
                    var avg = 0;
                    $scope.data.items.forEach(function (entry) {
                        avg = avg + entry.y;
                        if (averageValues === 3) {
                            var scatterData = {
                                x: entry.x,
                                y: avg / 4,
                                group: 1
                            };
                            averageValues = 0;
                            avg = 0;
                            $scope.data.items.add(scatterData);
                        } else {
                            averageValues++;
                        }

                    });
                }
            }
        });

        $scope.chart_options = {};
        $scope.chart_options.data = [];
        tenorService.get('statistics/generic').then(function (data) {
            var ns_instantiated = data.filter(function (d) {
                return d.name == 'ns_instantiated_requests';
            })[0];
            var ns_instantiated_ok = data.filter(function (d) {
                return d.name == 'ns_instantiated_requests_ok';
            })[0];
            var rejected = ns_instantiated.value - ns_instantiated_ok.value;

            $scope.chart_options.data.push({
                label: "Requests",
                value: ns_instantiated.value
            });
            $scope.chart_options.data.push({
                label: "Mapped",
                value: ns_instantiated_ok.value
            });
            $scope.chart_options.data.push({
                label: "Rejected",
                value: rejected
            });
        });

        //loading options
        $scope.loadingOptions = {
            active: false, // Defines current loading state
            text: "",
            className: '', // Custom class, added to directive
            overlay: true, // Display overlay
            spinner: true, // Display spinner
            spinnerOptions: {
                lines: 12, // The number of lines to draw
                length: 7, // The length of each line
                width: 4, // The line thickness
                radius: 10, // The radius of the inner circle
                rotate: 0, // Rotation offset
                corners: 1, // Roundness (0..1)
                color: '#000', // #rgb or #rrggbb
                direction: 1, // 1: clockwise, -1: counterclockwise
                speed: 2, // Rounds per second
                trail: 100, // Afterglow percentage
                opacity: 1 / 4, // Opacity of the lines
                fps: 20, // Frames per second when using setTimeout()
                zIndex: 2e9, // Use a high z-index by default
                className: 'dw-spinner', // CSS class to assign to the element
                top: 'auto', // Center vertically
                left: 'auto', // Center horizontally
                position: 'relative' // Element position
            }
        };
    });
