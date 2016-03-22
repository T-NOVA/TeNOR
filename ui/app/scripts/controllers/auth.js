'use strict';

angular.module('tNovaApp')
    .controller('AuthCtrl', function ($rootScope, $scope, $location, AuthService, $window) {

        $scope.loginGKProcess = function (username, password) {
            var user_id = 1;
            AuthService.loginGK(user_id, password).then(function (data) {
                    console.log(data);
                    if (data === '') return;
                    $window.localStorage.token = data.token.id;
                    $window.localStorage.expiration = data.token['valid-until'];
                    AuthService.profileGK(user_id, data.token.id).then(function (data) {
                        console.log(data);
                        $window.localStorage.user = JSON.stringify(data.info[0]);
                        $rootScope.user = data.info[0];
                        $location.path('/dashboard');
                    }, function (error) {
                        console.log(error);
                        $scope.loginError = 'Login failed';
                    });
                },
                function (error) {
                    $rootScope.loginError = 'Error with the Authentication module.';
                    //$rootScope.loginError = error;
                }
            );
        };

        $scope.login = function () {
            var username = $scope.username;
            var password = $scope.password;
            $rootScope.username = username;
            if (username && password) {
                $scope.loginGKProcess(username, password);
            } else {
                $scope.loginError = 'Username and password required';
            }
        };
    });
