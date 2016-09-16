'use strict';

angular.module('tNovaApp')
    .controller('PoPController', function ($scope, $window, tenorService, $interval, $modal, AuthService, infrRepoService) {

        console.log($window.localStorage.token);
        AuthService.get($window.localStorage.token, "admin/dc/").then(function (d) {
            console.log(d);
            $scope.registeredDcList = d.dclist;
            console.log($scope.registeredDcList)


            var url = 'pop/';
            infrRepoService.get(url).then(function (_data) {
                $scope.pops = _data;
                $scope.availableDcList = [];
                angular.forEach(_data, function (pop, index, array) {
                    url = pop.identifier.slice(1);
                    infrRepoService.get(url).then(function (_data) {

                        var exist = _.some($scope.registeredDcList, function (c) {
                            return _data.attributes['occi.epa.popuuid'] !== c;
                        });
                        console.log(exist);
                        if (!exist) {
                            $scope.availableDcList.push(_data.attributes);
                        }
                    });
                });
            });
        });

        $scope.addDialog = function (id) {
            console.log("dasda2" + id + "1dasda");
            if (id === "") {
                $scope.emptyId = true;
            }
            $scope.object = {};
            $scope.object.id = id;
            $modal({
                title: "Registring DC - " + id,
                template: "views/t-nova/modals/addPop.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.registerDc = function (obj) {
            var message = {
                "msg": "PoP Testbed",
                "dcname": "infrRepository-Pop-ID",
                "adminid": "kyestonUser",
                "password": "keystonePass",
                "extrainfo": "pop-ip=OPENSTACK_IP keystone-endpoint=http://OPENSTACK_IP:35357/v2.0 orch-endpoint=http://OPENSTACK_IP:8004/v1"
            };
            var pop = {
                "msg": obj.msg,
                "dcname": obj.id,
                "adminid": obj.adminName,
                "password": obj.adminPass,
                "extrainfo": "tenant-name=" + obj.tenantName + " pop-ip=" + obj.openstack_ip + " keystone-endpoint=http://" + obj.openstack_ip + ":35357/v2.0 orch-endpoint=http://" + obj.openstack_ip + ":8004/v1"
            };
            console.log(pop);
            AuthService.post($window.localStorage.token, "admin/dc/", pop).then(function (d) {
                console.log(d);
                $scope.registeredDcList = d.dclist;
                this.$hide();
            });
        };

        $scope.getPopInfo = function (popId) {
            console.log(popId);
            popId = popId + 1;
            AuthService.get($window.localStorage.token, "admin/dc/" + popId).then(function (data) {
                console.log(data);
                $scope.popInfo = data;
                //remove d.info[0].password
                $scope.jsonObj = JSON.stringify(data, undefined, 4);
                $modal({
                    title: "Pop - " + popId,
                    template: "views/t-nova/modals/info/showPop.html",
                    show: true,
                    scope: $scope,
                });
            });
        };

        $scope.removePopDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                template: "views/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });;
        };

        $scope.deleteItem = function (popId) {
            popId = popId + 1;
            AuthService.delete($window.localStorage.token, "admin/dc/" + popId).then(function (data) {
                console.log(data);
            });
        };

    });
