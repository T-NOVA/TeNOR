'use strict';

angular.module('tNovaApp')
    .controller('AuthCtrl', function ($rootScope, $scope, $location, AuthService, $window, $alert) {

        $scope.loginProcess = function (username, password) {
            console.log(username);
            //var user_id = 1;
            var user_id;
            var obj = {
                username: username,
                password: password
            }
            AuthService.login(obj).then(function(data){
                console.log(data);
                console.log(username);
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
            /*AuthService.loginGK(username, password).then(function (data) {
                    console.log(data);
                    if (data === '') return;
                    $window.localStorage.token = data.token.id;
                    $window.localStorage.expiration = data.token['valid-until'];
                    user_id = data.uid;
                    AuthService.profileGK(user_id, data.token.id).then(function (data) {
                        console.log(data);
                        $window.localStorage.user = JSON.stringify(data.info[0]);
                        $rootScope.user = data.info[0];
                        $location.path('/dashboard');
                    }, function (error) {
                        console.log(error);
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
                    });
                },
                function (error) {
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
                }
            );*/
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
