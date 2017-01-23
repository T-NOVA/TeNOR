'use strict';

angular.module('tNovaApp')
    .controller('configurationController', function ($window, $scope,  $filter, AuthService, $alert, tenorService) {
        $scope.user = {};
        console.log($window.localStorage);
        $scope.user.name = $window.localStorage.username;
        var uid = $window.localStorage.uid;

        $scope.update_user = function(user){
            console.log(user);
            AuthService.put('token', uid + '/update_password', user).then(function(d){
                console.log(d);
                $alert({
                    title: "Success: ",
                    content: "User password updated correctly.",
                    placement: 'top',
                    type: 'success',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
                $scope.user = {};
                $scope.user.name = $window.localStorage.username;
            }, function errorCallback(response) {
                console.log("Error");
                console.log(response);
                $alert({
                    title: "Error: ",
                    content: "User password not updated.",
                    placement: 'top',
                    type: 'danger',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
            });
        };
        $scope.registerUser = function (user) {
            console.log(user);
            if (user.username === undefined || user.password === undefined || user.password2 === undefined) {
                var error = "Some field is empty.."
                console.log(error);
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
                return;
            }
            if (!(user.password === user.password2)) {
                var error = "Password does not match."
                console.log(error);
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
                return;
            }
            if (user.isadmin) {
                user.isadmin = "y"
            } else {
                user.isadmin = "n"
            }

            var new_user = {
                username: user.username,
                password: user.password,
                isadmin: user.isadmin,
                accessList: "ALL"
            }
            AuthService.post($window.localStorage.token, "admin/user/", new_user).then(function (d) {
                console.log(d);
                $alert({
                    title: "Success: ",
                    content: "User created successfully",
                    placement: 'top',
                    type: 'success',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
            });

        }
    });
