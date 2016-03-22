'use strict';

angular.module('tNovaApp')
        .controller('UsersController', function ($scope, $resource, UserService) {
            console.log("Request");
            UserService.list(function (user) {
                console.log(user);

            });
            var Users = $resource('/rest/user/');
            console.log(Users);

            $scope.users = Users.query();

            $scope.addUser = function () {

                Users.save({name: $scope.name, lastName: $scope.lastName});
                $scope.users = Users.query();
                $scope.name = $scope.lastName = '';
            };

        }).controller('UserProfileController', function ($scope, $resource, UserService) {

    UserService.get(function (user) {
        console.log(user);
        console.log(user.name);
        $scope.user = user;
    });
});