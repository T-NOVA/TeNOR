'use strict';

angular.module('tNovaApp')
    .controller('PoPController', function ($scope, $window, tenorService, $interval, $modal, AuthService, infrRepoService) {

        console.log($window.localStorage.token);
        AuthService.get($window.localStorage.token, "admin/dc/").then(function (d) {
            console.log(d);
            $scope.registeredDcList = [];
            _.map(d.dclist, function (row, index) {
                $scope.registeredDcList.push({
                    id: d.dcid[index],
                    name: row
                })
            });
            console.log($scope.registeredDcList);

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
            if (id === "") {
                $scope.emptyId = true;
            }
            $scope.object = {};
            $scope.object.id = id;
            $scope.dc_default = {};
            $scope.openstack_ip = "define openstack IP";
            $scope.dc_default = {
                msg: "Description",
                id: "infrRepository-Pop-ID",
                adminid: "admin",
                password: "adminpass",
                openstack_ip: $scope.openstack_ip,
                keystone_api: $scope.openstack_ip + ":35357/v2.0",
                heat_api: $scope.openstack_ip + ":8004/v1",
                compute_api: $scope.openstack_ip + ":8774/v2.1",
                neutron_api: $scope.openstack_ip + ":9696/v2.0",
                dns: "8.8.8.8"
            }
            $modal({
                title: "Registring DC - " + id,
                template: "views/t-nova/modals/addPop.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.updateOpenstackIP = function (openstack_ip) {
            var keystone_version = $scope.dc_default.keystone_api.split(":")[1]
            var heat_version = $scope.dc_default.heat_api.split(":")[1]
            var compute_version = $scope.dc_default.compute_api.split(":")[1]
            var neutron_version = $scope.dc_default.neutron_api.split(":")[1]
            $scope.dc_default = {
                msg: $scope.dc_default.msg,
                id: $scope.dc_default.id,
                adminName: $scope.dc_default.adminName,
                tenantName: $scope.dc_default.tenantName,
                adminPass: $scope.dc_default.adminPass,
                openstack_ip: openstack_ip,
                keystone_api: openstack_ip + ":" + keystone_version,
                heat_api: openstack_ip + ":" + heat_version,
                compute_api: openstack_ip + ":" + compute_version,
                neutron_api: openstack_ip + ":" + neutron_version,
                dns: $scope.dc_default.dns
            }
        }

        $scope.registerDc = function (obj) {
            var message = {
                "msg": "PoP Testbed",
                "dcname": "infrRepository-Pop-ID",
                "adminid": "keystonUser",
                "password": "keystonePass",
                "extrainfo": "pop-ip=OPENSTACK_IP tenant-name=admin keystone-endpoint=http://OPENSTACK_IP:35357/v2.0 orch-endpoint=http://OPENSTACK_IP:8004/v1"
            };
            var pop = {
                "msg": obj.msg,
                "dcname": obj.id,
                "adminid": obj.adminName,
                "password": obj.adminPass,
                "extrainfo": "pop-ip=" + obj.openstack_ip + " tenant-name=" + obj.tenantName + " keystone-endpoint=http://" + obj.keystone_api + " orch-endpoint=http://" + obj.heat_api + " compute-endpoint=http://" + obj.compute_api + " neutron-endpoint=http://" + obj.neutron_api + " dns=" + obj.dns
            };
            console.log(pop);
            AuthService.post($window.localStorage.token, "admin/dc/", pop).then(function (d) {
                console.log(d);
                $scope.registeredDcList = d.dclist;
                //this.$hide();
            });
            this.$hide();
        };

        $scope.getPopInfo = function (popId) {
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
            AuthService.delete($window.localStorage.token, "admin/dc/" + popId).then(function (data) {
                console.log(data);
            });
        };

    });
