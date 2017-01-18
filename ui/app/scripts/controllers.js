'use strict';

angular.module('tNovaApp.controllers', [])

.controller('RootCtrl', function ($scope, $rootScope, Fullscreen) {
        // controls sidebar expand/close
        $rootScope.sidebarCollapse = false;
        $scope.toggleSidebar = function () {
            $rootScope.sidebarCollapse = !$rootScope.sidebarCollapse;
        };
        $scope.goFullscreen = function () {
            if (Fullscreen.isEnabled())
                Fullscreen.cancel();
            else
                Fullscreen.all();
        }
    })
    .controller('LockCtrl', function () {});
