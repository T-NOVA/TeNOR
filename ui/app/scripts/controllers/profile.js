'use strict';

angular.module('tNovaApp')
    .controller('ProfileCtrl', function ($scope, $window, $location, AuthService, ProfileService, TenantsService) {
        $scope.userCollection = [];
        ProfileService.getProfile().then(function (data) {
            $scope.profile = data;
            TenantsService.get(data.tenant_id).then(function (data) {
                $scope.profile.tenant_id = data.name;
            });
        });

        $scope.update = function (profile) {
            console.log('Update profile with: ');
            console.log(profile);

            ProfileService.updateProfile().then(
                function () {
                    console.log('Update ok.');
                },
                function (error) {
                    console.log(error);
                    $scope.profilePassError = error;
                }
            );
        };

        $scope.changePassword = function (object) {
            console.log('Update profile with: ');
            console.log(object);
            console.log($scope);

            var old_password = object.old_password;
            var password = object.password;
            var re_password = object.re_password;

            $scope.registerForm.oldPassError = false;
            $scope.registerForm.passError = false;
            $scope.registerForm.repassError = false;

            if (old_password && password && re_password) {
                if (password === re_password) {
                    //var data = {"old_password": old_password, "password": password, "re_password": re_password};
                    ProfileService.updatePass(old_password, password, re_password).then(
                        function (data) {
                            console.log(data);
                        },
                        function (error) {
                            $scope.profilePassError = error;
                        }
                    );
                } else {
                    console.log('ERROR1');
                    $scope.registerForm.repassError = true;
                    $scope.registerError = 'The repeat password is different from password.';
                }
            } else {
                console.log('ERROR2');
                if (!old_password) $scope.registerForm.oldPassError = true;
                if (!password) $scope.registerForm.passError = true;
                if (!re_password) $scope.registerForm.repassError = true;
                //if(!fullname) $scope.registerForm.fullnameError = true;
                //if(!org) $scope.registerForm.usernameError = true;
                $scope.registerError = 'All password fields are required.';
            }
        };
    });
