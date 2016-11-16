'use strict';

/**
 * @ngdoc overview
 * @name tNovaApp
 * @description
 * # tenor-ui
 *
 * Main module of the application.
 */

angular.module('tNovaApp', ['ui.router', 'ngSanitize', 'tNovaApp.config', 'tNovaApp.controllers', 'tNovaApp.directives', 'tNovaApp.services', 'smart-table', 'mgcrea.ngStrap', 'LocalStorageModule', 'cb.x2js', 'darthwade.dwLoading', 'checklist-model', 'angularResizable', 'FBAngular', 'ng.jsoneditor'])
    .config(function (localStorageServiceProvider) {
        localStorageServiceProvider
            .setPrefix('tNovaApp')
            .setStorageType('sessionStorage')
            .setNotify(true, true);
    }).config(
  ['$stateProvider', '$urlRouterProvider', '$httpProvider',
    function ($stateProvider, $urlRouterProvider, $httpProvider) {
                $stateProvider
                // Root state to master all
                    .state('root', {
                        abstract: true,
                        controller: 'rootCtrl',
                        views: {
                            '@': {
                                templateUrl: 'views/layout/tpl.common.html',
                                controller: ''
                            },
                            'header@root': {
                                templateUrl: 'views/layout/header.html',
                                controller: 'RootCtrl'
                            },
                            'sidebar@root': {
                                templateUrl: 'views/layout/sidebar.html',
                                controller: 'RootCtrl'
                            },
                            'main@root': {
                                template: '<div ui-view="master"></div>',
                                controller: 'RootCtrl'
                            },
                            'footer@root': {
                                templateUrl: 'views/layout/footer.html',
                                controller: 'RootCtrl'
                            },
                        }
                    })
                    .state('login', {
                        url: '/login',
                        templateUrl: 'views/user/login.html',
                        controller: 'AuthCtrl'
                    })
                    .state('root.profile', {
                        url: '/profile',
                        views: {
                            'master@root': {
                                templateUrl: 'views/user/profile.html',
                                controller: 'ProfileCtrl'
                            }
                        }
                    })
                    //catalogues
                    .state('root.ns', {
                        url: '/ns',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/ns.html',
                                controller: 'nsController'
                            }
                        }
                    })
                    .state('root.vnf', {
                        url: '/vnf',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/vnf.html',
                                controller: 'vnfController'
                            }
                        }
                    })
                    //instances
                    .state('root.nsInstances', {
                        url: '/nsInstances',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/nsInstances.html',
                                controller: 'nsInstancesController'
                            }
                        }
                    })
                    .state('root.vnfInstances', {
                        url: '/vnfInstances',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/vnfInstances.html',
                                controller: 'vnfInstancesController'
                            }
                        }
                    })
                    //monitoring
                    .state('root.nsMonitoring', {
                        url: '/nsMonitoring',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/nsMonitoring.html',
                                controller: 'nsMonitoringController'
                            }
                        }
                    })
                    .state('root.nsMonitoring2', {
                        url: '/nsMonitoring/:id',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/nsMonitoring.html',
                                controller: 'nsMonitoringController'
                            }
                        }
                    })
                    .state('root.vnfMonitoring', {
                        url: '/vnfMonitoring',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/vnfMonitoring.html',
                                controller: 'vnfMonitoringController'
                            }
                        }
                    })
                    .state('root.vnfMonitoring2', {
                        url: '/vnfMonitoring/:id',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/vnfMonitoring.html',
                                controller: 'vnfMonitoringController'
                            }
                        }
                    })
                    .state('root.mappingAlgorithm', {
                        url: '/mappingAlgorithm',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/mappingAlgorithm.html',
                                controller: 'mappingAlgorithmController'
                            }
                        }
                    })
                    .state('root.infrastructureRepository', {
                        url: '/infrastructureRepository',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/infrastructureRepository.html',
                                controller: 'infrastructureRepositoryController'
                            }
                        }
                    })
                    .state('root.configuration', {
                        url: '/configuration',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/configuration.html',
                                controller: 'configurationController'
                            }
                        }
                    })
                    .state('root.modules', {
                        url: '/modules',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/modules.html',
                                controller: 'modulesController'
                            }
                        }
                    })
                    //services
                    .state('root.nodes', {
                        url: '/nodes',
                        views: {
                            'master@root': {
                                templateUrl: 'views/nodes.html',
                                controller: 'NodesCtrl'
                            }
                        }
                    })
                    // Dashboard
                    .state('root.dashboard', {
                        url: '/dashboard',
                        views: {
                            'master@root': {
                                templateUrl: 'views/index.html',
                                controller: 'HomeController'
                            }
                        }
                    })
                    // PoP Information
                    .state('root.pops', {
                        url: '/pops',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/pop.html',
                                controller: 'PoPController'
                            }
                        }
                    }).state('root.nsdCreation', {
                        url: '/nsd_creation',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/descriptorCreation.html',
                                controller: 'descriptionCreationController'
                            }
                        }
                    }).state('root.logs', {
                        url: '/logs',
                        views: {
                            'master@root': {
                                templateUrl: 'views/t-nova/logs.html',
                                controller: 'logsController'
                            }
                        }
                    });

                $urlRouterProvider.otherwise('/login');

                /* Registers auth token interceptor, auth token is either passed by header or by query parameter
                 * as soon as there is an authenticated user */
                $httpProvider.interceptors.push(function ($q, $rootScope, $location, $window) {
                    return {
                        'request': function (config) {
                            var isRestCall = config.url.indexOf('rest') === 0;
                            var isRestCall = config.url.indexOf('login') !== -1;
                            var isRestCall = config.url.indexOf('rest/api/auth/token/') !== -1;
                            if (!isRestCall && angular.isDefined($window.localStorage.token)) {
                                //  if (angular.isDefined($window.localStorage.token)) {
                                var authToken = $window.localStorage.token;
                                if (tNovaAppConfig.useAuthTokenHeader) {
                                    config.headers['X-Auth-Token'] = authToken;
                                } else {
                                    config.url = config.url + '?token=' + authToken;
                                }
                                if (Math.floor(Date.now() / 1000) > $window.localStorage.expiration){
                                $window.localStorage.clear();
                                    $rootScope.logout();
                                  }
                            } else {
                              $location.path('/login');
                            }
                            return config || $q.when(config);
                        }
                    };
                });
                $httpProvider.interceptors.push(function ($q, $rootScope, $location, $window) {
                    return {
                        'responseError': function (rejection) {
                            var status = rejection.status;
                            var config = rejection.config;
                            var method = config.method;
                            var url = config.url;
                            if (Math.floor(Date.now() / 1000) > $window.localStorage.expiration)
                                $rootScope.logout();
                            else if (status === 401 && $window.localStorage.token !== null) {
                                $location.path('/login');
                            } else if (status === 401) {
                                $location.path('/login');
                            } else {
                                $rootScope.error = method + ' on ' + url + ' failed with status ' + status;
                            }
                            return $q.reject(rejection);
                        }
                    };
                });
    }
  ]
    ).run(function ($window, $rootScope, $location, $state, AuthService) {
        if ($window.localStorage.username) $rootScope.username = $window.localStorage.username;
        $rootScope.$state = $state;

        $rootScope.logout = function () {
            console.log('logout');
            if ($window.localStorage.user) $rootScope.user = JSON.parse($window.localStorage.user);

            AuthService.logout($window.localStorage.token).then(
                function () {
                    $window.localStorage.clear();
                    $location.path('/login');
                },
                function (error) {
                    $rootScope.error = error;
                }
            );
        };

        $rootScope
            .$on('$viewContentLoaded', function (event) {
                if (!$window.localStorage.token) {
                    //$location.path('/login');
                }
            });

        $rootScope
            .$on('$locationChangeStart', function (event, next, current) {
                if ($rootScope.user) {
                    var stat = {
                        'user_id': $rootScope.user.id,
                        'view': $location.path()
                    };
                }
                // check for the user's token and that we aren't going to the login view
                if ($window.localStorage.token === 'null' && ($location.path() !== '/register' && $location.path() !== '/recover_pass')) {
                    // go to the login view
                    $location.path('/login');
                }
            });

        $rootScope.sideBar = function () {
            $rootScope.sidebarCollapse = !$rootScope.sidebarCollapse;
        }
    });

var services = angular.module('tNovaApp.services', ['ngResource']);
var graph;
var defaultTimer = 50000; //2000
var defaultTimer2 = 5000; //2000
