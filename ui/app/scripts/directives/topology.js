'use strict';
angular.module('tNovaApp')
    .directive('topologySimple', function ($parse, $window) {
        // constants
        var width = 800,
            height = 800,
            fill = d3.scale.category20();
        return {
            restrict: 'E',
            link: function (scope, iElm, iAttrs, controller) {
                scope.$on('topologyData', function (events, ntdata) {
                    if (ntdata) {
                        var inNodes = ntdata.nodes;
                        var inEdges = ntdata.links;
                        var container = iElm[0];
                        // legend moved to topology controller
                        var data = {
                            nodes: inNodes,
                            edges: inEdges
                        };
                        var color = '#66FFFF',
                            hl = '#0066FF',
                            hover = '#33CC33',
                            BLACK = '#2B1B17';
                        var options = {
                            width: '100%',
                            height: '500px',
                            nodes: {
                                widthMin: 20,
                                widthMax: 200,
                                fontColor: BLACK
                            },
                            edges: {
                                length: 80,
                                color: {
                                    color: '#070707',
                                    highlight: hl,
                                    hover: hover
                                }
                            },
                            physics: {
                                barnesHut: {
                                    gravitationalConstant: -7025
                                }
                            },
                            hover: true,
                            groups: {
                                'pop': {
                                    shape: 'image',
                                    image: 'img/infr_repo/pop.png'
                                }
                            },
                            click: "my_tree_handler()",
                            keyboard: true,
                            tooltip: {
                                delay: 300,
                                fontColor: "black",
                                fontSize: 14, // px
                                fontFace: "verdana",
                                color: {
                                    border: "#666",
                                    background: "#FFFFC6"
                                }
                            }
                        };
                        var graph = new vis.Network(container, data, options);
                        graph.on('click', function (properties) {
                            var ty;
                            ntdata.nodes.forEach(function (entry) {
                                console.log(entry);
                                console.log(entry.id);
                                console.log(properties.nodes);
                                console.log(entry.id === properties.nodes[0]);
                                if (entry.id === properties.nodes[0]) ty = entry.group;
                            });
                            console.log('Clicked node ' + properties.nodes + " " + ty);
                            console.log(scope);
                            scope.ui_handler(properties.nodes[0], ty);
                            //test. my_tree_handler();
                        });

                        return graph;
                    }
                });
            }
        };
    })
    .directive('topologyComplete', function ($parse, $window) {
        // constants
        var width = 800,
            height = 800
            /*,
                        fill = d3.scale.category20();*/
        return {
            restrict: 'E',
            link: function (scope, iElm, iAttrs, controller) {
                    scope.$on('completeTopologyData', function (events, ntdata) {
                        console.log("completeTopologyData data is updated.");
                        if (ntdata) {
                            var inNodes = ntdata.nodes;
                            var nodes = inNodes;
                            var edges = inEdges;
                            var inEdges = ntdata.links;
                            var container = iElm[0];
                            var data = {
                                nodes: inNodes,
                                edges: inEdges
                            };
                            var color = '#66FFFF',
                                hl = '#0066FF',
                                hover = '#33CC33',
                                BLACK = '#2B1B17';
                            var options = {
                                width: '100%',
                                height: '500px',
                                nodes: {
                                    shape: 'dot',
                                    size: 20,
                                    font: {
                                        size: 15,
                                        color: '#ffffff'
                                    },
                                    borderWidth: 2
                                },
                                edges: {
                                    width: 2
                                },
                                groups: {
                                    diamonds: {
                                        color: {
                                            background: 'red',
                                            border: 'white'
                                        },
                                        shape: 'diamond'
                                    },
                                    dotsWithLabel: {
                                        label: "I'm a dot!",
                                        shape: 'dot',
                                        color: 'cyan'
                                    },
                                    mints: {
                                        color: 'rgb(0,255,140)'
                                    },
                                    icons: {
                                        shape: 'icon',
                                        icon: {
                                            face: 'FontAwesome',
                                            code: '\uf0c0',
                                            size: 50,
                                            color: 'orange'
                                        }
                                    },
                                    source: {
                                        color: {
                                            border: 'white'
                                        }
                                    }
                                }
                            };
                            var graph = new vis.Network(container, data, options);
                            graph.on("click", onClick);
                            return graph;
                        } //if
                    }); //scope on
                } //link
        }; //return
    })
    .directive('visNetwork', function () {
        return {
            restrict: 'E',
            require: '^ngModel',
            scope: {
                ngModel: '=',
                onSelect: '&',
                options: '='
            },
            link: function ($scope, $element, $attrs, ngModel) {
                var network = new vis.Network($element[0], $scope.ngModel, $scope.options || {});
                var onSelect = $scope.onSelect() || function (prop) {};
                network.on('select', function (properties) {
                    onSelect(properties);
                });

                network.on("initRedraw", function () {
                    // do something like move some custom elements?
                });
                network.on("beforeDrawing", function (ctx) {
                    for (var nodeId in $scope.ngModel.nodes._data) {
                        if ($scope.ngModel.nodes._data[nodeId].group === 'physical') {
                            var nodeType = $scope.ngModel.nodes._data[nodeId];
                            var nodePosition = network.getPositions([nodeId]);

                            ctx.strokeStyle = '#A6D5F7';
                            ctx.fillStyle = '#A6D5F7';
                            ctx.square(nodePosition[nodeId].x, nodePosition[nodeId].y, 50, 40);
                            ctx.fill();
                            ctx.stroke();
                        }
                    };
                });
                network.on("dragStart", function (properties) {
                    if (!properties.nodes.length) return;
                    $scope.setNodesMoveable(properties.nodes, true);
                });

                network.on("dragEnd", function (properties) {
                    if (!properties.nodes.length) return;
                    $scope.setNodesMoveable(properties.nodes, false);
                });

                $scope.setNodesMoveable = function (nodeIds, isMoveable) {
                    var updates = [];
                    var isFixed = !isMoveable;
                    for (var i = nodeIds.length; i--;) {
                        updates.push({
                            id: nodeIds[i],
                            fixed: {
                                x: isFixed,
                                y: isFixed
                            }
                        });
                    }
                    $scope.ngModel.nodes.update(updates);
                };
            }
        }
    });

function onClick(selectedItems) {
    var nodes = new vis.DataSet();
    var edges = new vis.DataSet();
    console.log(selectedItems);
    nodes.add(ntdata.nodes);
    edges.add(ntdata.links);
    console.log(nodes);
    var nodeId;
    var degrees = 2;
    // we get all data from the dataset once to avoid updating multiple times.
    var allNodes = nodes.get({
        returnType: "Object"
    });
    if (selectedItems.nodes.length === 0) {
        // restore on unselect
        for (nodeId in allNodes) {
            if (allNodes.hasOwnProperty(nodeId)) {
                allNodes[nodeId].color = undefined;
                if (allNodes[nodeId].oldLabel !== undefined) {
                    allNodes[nodeId].label = allNodes[nodeId].oldLabel;
                    allNodes[nodeId].oldLabel = undefined;
                }
                allNodes[nodeId]['levelOfSeperation'] = undefined;
                allNodes[nodeId]['inConnectionList'] = undefined;
            }
        }
    } else {
        // we clear the level of separation in all nodes.
        clearLevelOfSeperation(allNodes);

        // we will now start to collect all the connected nodes we want to highlight.
        var connectedNodes = selectedItems.nodes;

        // we can store them into levels of separation and we could then later use this to define a color per level
        // any data can be added to a node, this is just stored in the nodeObject.
        storeLevelOfSeperation(connectedNodes, 0, allNodes);
        for (var i = 1; i < degrees + 1; i++) {
            appendConnectedNodes(connectedNodes);
            storeLevelOfSeperation(connectedNodes, i, allNodes);
        }
        for (nodeId in allNodes) {
            if (allNodes.hasOwnProperty(nodeId)) {
                if (allNodes[nodeId]['inConnectionList'] === true) {
                    if (allNodes[nodeId]['levelOfSeperation'] !== undefined) {
                        if (allNodes[nodeId]['levelOfSeperation'] >= 2) {
                            allNodes[nodeId].color = 'rgba(150,150,150,0.75)';
                        } else {
                            allNodes[nodeId].color = undefined;
                        }
                    } else {
                        allNodes[nodeId].color = undefined;
                    }
                    if (allNodes[nodeId].oldLabel !== undefined) {
                        allNodes[nodeId].label = allNodes[nodeId].oldLabel;
                        allNodes[nodeId].oldLabel = undefined;
                    }
                } else {
                    allNodes[nodeId].color = 'rgba(200,200,200,0.5)';
                    if (allNodes[nodeId].oldLabel === undefined) {
                        allNodes[nodeId].oldLabel = allNodes[nodeId].label;
                        allNodes[nodeId].label = "";
                    }
                }
            }
        }
    }
    var updateArray = [];
    for (nodeId in allNodes) {
        if (allNodes.hasOwnProperty(nodeId)) {
            updateArray.push(allNodes[nodeId]);
        }
    }
    nodes.update(updateArray);
    //data.nodes = [];
    //graph.setData(data);
    /*
                            console.log(ntdata);
                            console.log(properties);
                            var ty;
                            ntdata.nodes.forEach(function(entry){
                                console.log(entry);
                                console.log(entry.id);
                                console.log(properties.nodes);
                                console.log(entry.id === properties.nodes[0]);
                                if(entry.id === properties.nodes[0]) ty = entry.group;
                            });
                            console.log('Clicked node ' + properties.nodes + " "+ty);
                            console.log(scope);
                            scope.ui_handler(properties.nodes[0], ty);*/
    //test. my_tree_handler();
}

function storeLevelOfSeperation(connectedNodes, level, allNodes) {
    console.log("STORE SEPARATION");
    console.log(connectedNodes);
    for (var i = 0; i < connectedNodes.length; i++) {
        var nodeId = connectedNodes[i];
        if (allNodes[nodeId]['levelOfSeperation'] === undefined) {
            allNodes[nodeId]['levelOfSeperation'] = level;
        }
        allNodes[nodeId]['inConnectionList'] = true;
    }
}

function clearLevelOfSeperation(allNodes) {
    for (var nodeId in allNodes) {
        if (allNodes.hasOwnProperty(nodeId)) {
            allNodes[nodeId]['levelOfSeperation'] = undefined;
            allNodes[nodeId]['inConnectionList'] = undefined;
        }
    }
}

/**
 * Add the connected nodes to the list of nodes we already have
 *
 *
 */
function appendConnectedNodes(sourceNodes) {
    var tempSourceNodes = [];
    // first we make a copy of the nodes so we do not extend the array we loop over.
    for (var i = 0; i < sourceNodes.length; i++) {
        tempSourceNodes.push(sourceNodes[i])
    }

    for (i = 0; i < tempSourceNodes.length; i++) {
        var nodeId = tempSourceNodes[i];
        if (sourceNodes.indexOf(nodeId) == -1) {
            sourceNodes.push(nodeId);
        }
        var connectedNodes = graph.getConnectedNodes(nodeId);
        addUnique(connectedNodes, sourceNodes);
    }
    tempSourceNodes = null;
}

/**
 * Join two arrays without duplicates
 * @param fromArray
 * @param toArray
 */
function addUnique(fromArray, toArray) {
    for (var i = 0; i < fromArray.length; i++) {
        if (toArray.indexOf(fromArray[i]) == -1) {
            toArray.push(fromArray[i]);
        }
    }
}
