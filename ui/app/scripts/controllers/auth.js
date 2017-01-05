'use strict';

angular.module('tNovaApp')
    .controller('AuthCtrl', function ($rootScope, $scope, $location, AuthService, $window, $alert) {

        $scope.loginProcess = function (username, password) {
            var user_id;
            var obj = {
                username: username,
                password: password
            }
            AuthService.login(obj).then(function(data){
                $window.localStorage.username = username
                $window.localStorage.token = data.token;
                $window.localStorage.expiration = data.expires_at;
                $window.localStorage.uid = data.uid;
                $location.path('/dashboard');
            },function (error) {
                $rootScope.loginError = 'Error with the Authentication module.';
                $scope.loginError = 'Login failed';
                $alert({
                    title: "Error: ",
                    content: error,
                    placement: 'top',
                    type: 'danger',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
                //$rootScope.loginError = error;
            });
        };

        $scope.login = function () {
            var username = $scope.username;
            var password = $scope.password;
            $rootScope.username = username;
            if (username && password) {
                $scope.loginProcess(username, password);
            } else {
                $scope.loginError = 'Username and password required';
            }
        };
    });
